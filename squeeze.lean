import analysis.metric_space

local notation f `→_{`:50 a `}`:0 b := filter.tendsto f (nhds a) (nhds b)

variables {α : Type*} [decidable_linear_ordered_comm_group α]

lemma abs_bound (a b : α) : abs a ≤ b ↔ (-b ≤ a) ∧ (a ≤ b) :=
begin
split,
{ intro bound,
  split,
  { have b_ineq : -b ≤ 0 := by simpa using neg_le_neg (le_trans (abs_nonneg a) bound), 
  by_cases H : 0 ≤ a,
  { exact le_trans b_ineq H },
  { simp at H, 
      rw [abs_of_neg H] at bound,
      simpa using neg_le_neg bound } },
  { exact le_trans (le_abs_self a) bound }},
{ intro H,
  cases H with a_ge a_le,
  have a_ge' : -a ≤ b := by simpa using neg_le_neg a_ge, clear a_ge,
  exact max_le a_le a_ge' }
end

lemma abs_bound' {a b : α} : abs a < b ↔ (-b < a) ∧ (a < b) :=
begin
split,
{ intro bound,
  split,
  { have b_ineq : -b < 0 := by simpa using neg_lt_neg (lt_of_le_of_lt (abs_nonneg a) bound), 
    by_cases H : 0 ≤ a,
    { exact lt_of_lt_of_le b_ineq H },
    { simp at H, 
        rw [abs_of_neg H] at bound,
        simpa using neg_lt_neg bound } },
  { exact lt_of_le_of_lt (le_abs_self a) bound } },
{ intro H,
  cases H with a_gt a_lt,
  have a_gt' : -a < b := by simpa using neg_lt_neg a_gt, clear a_gt,
  exact max_lt a_lt a_gt' }
end

lemma squeeze {X : Type*} [metric_space X] (f g h : X → ℝ) (x₀ : X) (y : ℝ): 
(∀ x : X, f x ≤ g x) → (∀ x : X, g x ≤ h x) → (f →_{x₀} y) → (h →_{x₀} y) → (g →_{x₀} y) :=
begin
intros ineq_fg ineq_gh lim_f lim_h,
apply  tendsto_nhds_of_metric.2,
intros ε ε_pos,
rcases (tendsto_nhds_of_metric.1 lim_f ε ε_pos) with ⟨δ_f, δ_f_pos, ineq_lim_f⟩,
rcases (tendsto_nhds_of_metric.1 lim_h ε ε_pos) with ⟨δ_h, δ_h_pos, ineq_lim_h⟩,
existsi (min δ_f δ_h),
existsi lt_min δ_f_pos δ_h_pos,
intros x dist_x,

have dist_x_δ_f := lt_of_lt_of_le dist_x (min_le_left δ_f δ_h),
have abs_f_x := ineq_lim_f dist_x_δ_f, clear dist_x_δ_f,
rw [show dist (f x) y = abs (f x - y), from rfl] at abs_f_x,

have dist_x_δ_h := lt_of_lt_of_le dist_x (min_le_right δ_f δ_h),
have abs_h_x := ineq_lim_h dist_x_δ_h, clear dist_x_δ_h,
rw [show dist (h x) y = abs (h x - y), from rfl] at abs_h_x,

have sub_f_gt := (abs_bound'.1 abs_f_x).left,
have sub_h_lt := (abs_bound'.1 abs_h_x).right,

have g_gt := lt_of_lt_of_le sub_f_gt ((sub_le_sub_iff_right y).2 (ineq_fg x)),
have g_lt := lt_of_le_of_lt ((sub_le_sub_iff_right y).2 (ineq_gh x)) sub_h_lt,

exact abs_bound'.2 ⟨g_gt, g_lt⟩
end