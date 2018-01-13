import analysis.real
import analysis.metric_space
import analysis.limits
import analysis.topology.continuity
import analysis.topology.topological_structures
import algebra.module
import algebra.linear_algebra.prod_module
import order.filter

noncomputable theory
local attribute [instance] classical.prop_decidable

--local notation f `→_{` a `}` b := filter.tendsto f (nhds a) (nhds b)
local notation f `→_{`:50 a `}`:0 b := filter.tendsto f (nhds a) (nhds b)

lemma abs1 : abs (1:ℝ) = 1 :=
abs_of_pos zero_lt_one


variables {V : Type*} [vector_space ℝ V] {W : Type*} [vector_space ℝ W]

structure vector_space_norm (V : Type*) [vector_space ℝ V] :=
  (map : V → ℝ)
  (nonneg : ∀ e : V, 0 ≤ map e)
  (eq_zero : ∀ e : V, map e = 0 → e = 0)
  (triangle : ∀ e f : V, map (e + f) ≤ map e + map f)
  (homo : ∀ l : ℝ, ∀ e : V, map (l • e) = abs(l) * map e)

instance : has_coe_to_fun (vector_space_norm V) := 
⟨_, vector_space_norm.map⟩

@[simp]
lemma zero_norm (N : vector_space_norm V) : N 0 = 0 :=
by simpa using N.homo 0 0

lemma homo_norm {N : vector_space_norm V} (l : ℝ) (a : V): N (l•a) = (abs l)*(N a) :=
N.homo l a

variables {α : Type*} [decidable_linear_order α]
lemma max_ge_of_left_ge {a b : α} ( c: α ) : a ≤ b → a ≤ max b c :=
assume H,  le_trans H (le_max_left b c)

lemma max_ge_of_right_ge {a c : α} (b :α) : a ≤ c → a ≤ max b c :=
assume H, le_trans H (le_max_right b c)

lemma max_monotone_fun {α : Type*} [decidable_linear_order α] {β : Type*} [decidable_linear_order β] 
{f : α → β} (H : monotone f) (a a' : α)  :  max (f a) (f a') =  f(max a a') :=
begin
by_cases a ≤ a',
{ have fa_le_fa' := H h,
  rw max_comm,
  rw max_eq_left fa_le_fa',
  have T :=  max_eq_left h,
  rw max_comm at T,
  rw T },
{ have h' : a' ≤ a := le_of_not_ge h,
  rw max_eq_left (H h'),
  rw  max_eq_left h' }
end

lemma monotone_mul_nonneg (a : ℝ) : 0 ≤ a → monotone (λ x, a*x) :=
assume a_non_neg b c b_le_c, mul_le_mul_of_nonneg_left b_le_c a_non_neg

def product_norm (NV : vector_space_norm V) (NW : vector_space_norm W) : vector_space_norm (V × W)  :=
{ map :=  λ x, max (NV x.1) (NW x.2), 
  nonneg := assume x, max_ge_of_left_ge (NW x.2) (NV.nonneg x.1),
  eq_zero := begin
    intros x max_zero,

    have left := le_max_left (NV x.1) (NW x.2),
    rw max_zero at left,
    have x1_zero := NV.eq_zero x.1 (le_antisymm left (NV.nonneg x.1)),
    
    have right := le_max_right (NV x.1) (NW x.2),
    rw max_zero at right,
    have x2_zero := NW.eq_zero x.snd (le_antisymm right (NW.nonneg x.2)),
    
    cases x,
    simp at *,
    rw[x1_zero, x2_zero],
    refl
  end,
  triangle := begin
    intros x y,
    have ineq1 : NV ((x + y).fst) ≤ max (NV (x.fst)) (NW (x.snd)) + max (NV (y.fst)) (NW (y.snd)) := 
    begin
      simp,
      have A :=  le_max_left (NV x.1) (NW x.2),
      have B :=  le_max_left (NV y.1) (NW y.2),
      exact le_trans (NV.triangle x.1 y.1) (add_le_add A B),
    end,
    have ineq2 : NW ((x + y).snd) ≤ max (NV (x.fst)) (NW (x.snd)) + max (NV (y.fst)) (NW (y.snd)) := 
    begin
      simp,
      have A :=  le_max_right (NV x.1) (NW x.2),
      have B :=  le_max_right (NV y.1) (NW y.2),
      exact le_trans (NW.triangle x.2 y.2) (add_le_add A B),
    end,
    exact max_le ineq1 ineq2
  end,
  homo := begin
    intros l x,
    dsimp[(•)],
    rw [homo_norm l x.fst],
    rw [homo_norm l x.snd],
    apply max_monotone_fun _,
    exact monotone_mul_nonneg (abs l) (abs_nonneg l),
  end }


def metric_of_norm {V : Type*} [vector_space ℝ V] (N : vector_space_norm V) : metric_space V :=
{ dist := λ x y, N (x - y),
  dist_self := by simp,
  eq_of_dist_eq_zero := assume x y N0, eq_of_sub_eq_zero (N.eq_zero _ N0),
  dist_comm := assume x y, by simpa [abs1] using (N.homo (-1:ℝ) (x -y)).symm,
  dist_triangle := assume x y z, by simpa using N.triangle (x-y) (y-z) }

class normed_space (type : Type*) extends vector_space ℝ type :=
(norm : vector_space_norm type)

variables {E : Type*} {F : Type*} {G : Type*} [normed_space E] [normed_space F] [normed_space G]

def norm : E → ℝ := normed_space.norm E
local notation `∥` e `∥` := norm e

@[simp]
lemma zero_norm' : ∥(0:E)∥ = 0 :=
zero_norm _

lemma non_neg_norm : ∀ e : E, 0 ≤ ∥e∥ :=
vector_space_norm.nonneg _

lemma norm_non_zero_of_non_zero (e : E) : e ≠ 0 → ∥ e ∥ ≠ 0 :=
not_imp_not.2 (vector_space_norm.eq_zero _ _)

lemma norm_pos_of_non_zero (e : E) : e ≠ 0 → ∥ e ∥ > 0 :=
assume e_non_zero, lt_of_le_of_ne (non_neg_norm _) (ne.symm (norm_non_zero_of_non_zero e e_non_zero))

lemma triangle_ineq (a b : E) : ∥ a + b ∥ ≤ ∥ a ∥ + ∥ b ∥ :=
vector_space_norm.triangle _ _ _

lemma homogeneity (a : E) (s : ℝ): ∥ s • a ∥ = (abs s)* ∥ a ∥ :=
vector_space_norm.homo _ _ _


section normed_space_topology

instance normed_space.to_metric_space {A : Type*} [An : normed_space A] : metric_space A :=
metric_of_norm An.norm

lemma tendsto_iff_distance_tendsto_zero { X Y : Type*} [topological_space X] [metric_space Y]
(f : X → Y) (x : X) (y : Y): (f →_{x} y) ↔ ((λ x', dist (f x') y) →_{x} 0) :=
begin
split,
{ intro lim,
  have lim_y: (λ x', y) →_{x} y := continuous_iff_tendsto.1 (@continuous_const X Y _ _ y) x,
  have lim : (λ x', (f x', y)) →_{x} (y, y) := sorry,
  have lim2 := continuous_iff_tendsto.1 (@continuous_dist' Y _) (y, y),
  simp at lim2,
  exact filter.tendsto_compose lim lim2,  
 },
{ admit }
end

lemma tendsto_iff_norm_tends_to_zero (f : E → F) (a : E) (b : F) : (f →_{a} b) ↔ ((λ e, ∥ f e - b ∥) →_{a} 0) :=
begin
split,
{ admit },
{ admit }
end

lemma squeeze_zero {T : Type*} [topological_space T] (f g : T → ℝ) (t₀ : T) : 
(∀ t : T, 0 ≤ f t) → (∀ t : T, f t ≤ g t) → (g →_{t₀} 0) → (f →_{t₀} 0) :=
sorry

lemma lim_norm (E : Type*) [normed_space E] : ((λ e, ∥e∥) : E → ℝ) →_{0} 0 :=
sorry

lemma tendsto_smul {f : E → ℝ} { g : E → F} {e : E} {s : ℝ} {b : F} :
(f →_{e} s) → (g →_{e} b) → ((λ e, (f e) • (g e)) →_{e} s • b) := 
sorry

instance product_normed_space [nvsE : normed_space E] [nvsF : normed_space F] : normed_space (E × F) := 
{ norm := product_norm nvsE.norm nvsF.norm, 
..prod.vector_space}


--set_option pp.all true
instance normed_top_monoid  : topological_add_monoid E  := 
{ continuous_add := begin 
apply continuous_iff_tendsto.2 _,
intro x,
have := (tendsto_iff_norm_tends_to_zero (λ (p : E × E), p.fst + p.snd) x (x.1 + x.2)).2,
--apply this,
admit
end }

end normed_space_topology

section continuous_linear_maps

-- TODO: relate to is_continuous
def is_continuous_linear_map (L : E → F) := (is_linear_map L) ∧  ∃ M, M > 0 ∧ ∀ x : E, ∥ L x ∥ ≤ M *∥ x ∥ 

-- TODO: Clean up this proof
lemma comp_continuous_linear_map (L : E → F) (P : F → G) : 
is_continuous_linear_map L → is_continuous_linear_map P → is_continuous_linear_map (P ∘ L) :=
begin
intros HL HP,
rcases HL with ⟨lin_L , M, Mpos, ineq_L⟩,
rcases HP with ⟨lin_P , M', M'pos, ineq_P⟩,
split,
{ exact is_linear_map.comp lin_P lin_L },
{ existsi M*M',
  split,
  { exact mul_pos Mpos M'pos },
  { unfold function.comp,
    intro x,
    specialize ineq_P (L x),
    specialize ineq_L x,
    have fact : M'*∥L x∥ ≤ M * M' * ∥x∥ := -- prepare for PAIN
      begin 
      have ineq := mul_le_mul_of_nonneg_left ineq_L (le_of_lt M'pos),
      rw mul_comm, 
      rw mul_comm at ineq, 
      rw ←mul_assoc at ineq,
      rw mul_comm M,  
      exact ineq
      end ,
    exact le_trans ineq_P fact }
   }
end

lemma lim_zero_cont_lin_map (L : E → F) : is_continuous_linear_map L → (L →_{0} 0) :=
sorry

end continuous_linear_maps




-- set_option trace.class_instances true
example (f g : E → F) : (f →_{0} 0) → (g →_{0} 0) → ((λ x, f x + g x) →_{0} 0) :=
begin
intros Hf Hg,
have := tendsto_add Hf Hg,
simp at this,
exact this,
end

