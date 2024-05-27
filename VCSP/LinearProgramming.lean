import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.Data.Matrix.ColumnRowPartitioned
import Mathlib.Algebra.Order.CompleteField
import VCSP.FarkasBartl

open scoped Matrix


section inequalities_only

/-!

# Linear programming

We define linear programs over an `OrderedSemiring R` in the standard matrix form.

## Main definitions
 * `StandardLP` defines a linear program in the standard form
    (maximize `cᵀx` such that `A x ≤ b` and `x ≥ 0`).
 * `StandardLP.IsSolution` tells if given vector is a solution satisfying given standard LP.
 * `StandardLP.IsFeasible` tells if given standard LP has any solution.
 * `StandardLP.Reaches` tells if given value can be obtained as a cost of any solution of given
    standard LP.
 * `StandardLP.dual` defines a dual problem to given standard LP.

## Main results

* `StandardLP.weakDuality`: The weak duality theorem (`cᵀx` such that `A x ≤ b` and `x ≥ 0` is
   always less or equal to `bᵀy` such that `Aᵀ y ≥ c` and `y ≥ 0`).
* `StandardLP.strongDuality`: TODO!

-/

/-- Linear program in the standard form. Variables are of type `n`. Conditions are indexed by type `m`. -/
structure StandardLP (n m R : Type*) [Fintype n] [Fintype m] [OrderedSemiring R] where
  /-- Matrix of coefficients -/
  A : Matrix m n R
  /-- Right-hand side -/
  b : m → R
  /-- Objective function coefficients -/
  c : n → R

variable {n m R : Type*} [Fintype n] [Fintype m]

/-- Vector `x` is a solution to linear program `P` iff all entries of `x` are nonnegative and its
multiplication by matrix `A` from the left yields a vector whose all entries are less or equal to
corresponding entries of the vector `b`. -/
def StandardLP.IsSolution [OrderedSemiring R] (P : StandardLP n m R) (x : n → R) : Prop :=
  P.A *ᵥ x ≤ P.b ∧ 0 ≤ x

/-- Linear program `P` is feasible iff there is a vector `x` that is a solution to `P`. -/
def StandardLP.IsFeasible [OrderedSemiring R] (P : StandardLP n m R) : Prop :=
  ∃ x : n → R, P.IsSolution x

/-- Linear program `P` reaches objective value `v` iff there is a solution `x` such that,
when its entries are elementwise multiplied by the costs (given by the vector `c`) and summed up,
the result is the value `v`. -/
def StandardLP.Reaches [OrderedSemiring R] (P : StandardLP n m R) (v : R) : Prop :=
  ∃ x : n → R, P.IsSolution x ∧ P.c ⬝ᵥ x = v

/-- Dual linear program to given linear program `P` in the standard form.
The matrix gets transposed and its values flip signs.
The original cost function gets flipped signs as well and becomes the new righ-hand side vector.
The original righ-hand side vector becomes the new vector of objective function coefficients. -/
def StandardLP.dual [OrderedRing R] (P : StandardLP m n R) : StandardLP n m R :=
  ⟨-P.Aᵀ, -P.c, P.b⟩

/-- Objective values reached by linear program `P` are all less or equal to all objective values
reached by the dual of `P`. -/
theorem StandardLP.weakDuality [OrderedCommRing R] {P : StandardLP n m R}
    {p : R} (hP : P.Reaches p) {q : R} (hD : P.dual.Reaches q) :
    p ≤ q := by
  obtain ⟨x, ⟨hxb, h0x⟩, rfl⟩ := hP
  obtain ⟨y, ⟨hyc, h0y⟩, rfl⟩ := hD
  dsimp only [StandardLP.dual] at hyc ⊢
  have hy : P.A *ᵥ x ⬝ᵥ y ≤ P.b ⬝ᵥ y
  · exact Matrix.dotProduct_le_dotProduct_of_nonneg_right hxb h0y
  have hx : P.c ⬝ᵥ x ≤ P.Aᵀ *ᵥ y ⬝ᵥ x
  · rw [←neg_le_neg_iff, ←Matrix.neg_dotProduct, ←Matrix.neg_dotProduct, ←Matrix.neg_mulVec]
    exact Matrix.dotProduct_le_dotProduct_of_nonneg_right hyc h0x
  rw [Matrix.dotProduct_comm (P.Aᵀ *ᵥ y), Matrix.dotProduct_mulVec, Matrix.vecMul_transpose] at hx
  exact hx.trans hy

-- Does not hold as such.
-- We would need further assumption that the supremum of `P` is attained (i.e., `P` has a maximum).
-- Our use case actually allow us to derive that `P` is a closed set.
-- Can we do something easier tho?
lemma intersect_of_both_dualities_of_both_nonempty [ConditionallyCompleteLinearOrder R]
    {P Q : Set R} (hP : P.Nonempty) (hQ : Q.Nonempty)
    (hPQ : ∀ p ∈ P, ∀ q ∈ Q, p ≤ q) (hR : ∀ r : R, (∃ p ∈ P, r < p) ≠ (∃ q ∈ Q, q ≤ r)) :
    ∃ x, x ∈ P ∧ x ∈ Q := by
  specialize hR (sSup P)
  have sSupP_in_P : sSup P ∈ P
  · sorry -- `apply IsGreatest.csSup_mem`
  have left_false : (∃ p ∈ P, sSup P < p) = False
  · simp_rw [eq_iff_iff, iff_false, not_exists, not_and, not_lt]
    intro x xin
    refine le_csSup ?_ xin
    obtain ⟨q₀, hq₀⟩ := hQ
    use q₀
    intro p₀ hp₀
    exact hPQ p₀ hp₀ q₀ hq₀
  simp [left_false] at hR
  obtain ⟨x, hxQ, hxsSupQ⟩ := hR
  exact ⟨x, eq_of_le_of_le hxsSupQ (hPQ _ sSupP_in_P x hxQ) ▸ sSupP_in_P, hxQ⟩

theorem StandardLP.strongDuality [ConditionallyCompleteLinearOrderedField R] [DecidableEq m]
    {P : StandardLP m n R} (hP : P.IsFeasible) (hD : P.dual.IsFeasible) :
    ∃ r : R, P.Reaches r ∧ P.dual.Reaches r := by
  apply intersect_of_both_dualities_of_both_nonempty
  · obtain ⟨p, _⟩ := hP
    use P.c ⬝ᵥ p
    use p
  · obtain ⟨d, _⟩ := hD
    use P.dual.c ⬝ᵥ d
    use d
  · intro p hp q hq
    exact StandardLP.weakDuality hp hq
  · intro r
    show
      (∃ p, (∃ y', (P.A *ᵥ y' ≤ P.b ∧ 0 ≤ y') ∧ P.c ⬝ᵥ y' = p) ∧ r < p) ≠
      (∃ q, (∃ x', (-P.Aᵀ *ᵥ x' ≤ -P.c ∧ 0 ≤ x') ∧ P.b ⬝ᵥ x' = q) ∧ q ≤ r)
    simp
      only [exists_exists_and_eq_and]
    show
      (∃ y', (P.A *ᵥ y' ≤ P.b ∧ 0 ≤ y') ∧ r < P.c ⬝ᵥ y') ≠
      (∃ x', (-P.Aᵀ *ᵥ x' ≤ -P.c ∧ 0 ≤ x') ∧ P.b ⬝ᵥ x' ≤ r)
    convert
      (inequalityFarkas
        (Matrix.fromRows (-P.Aᵀ) (fun _ : Unit => P.b))
        (Sum.elim (-P.c) (fun _ : Unit => r))
      ).symm
          using 1
    · constructor
      · intro ⟨y', ⟨hAy', hy'⟩, hcy'⟩
        use Sum.elim y' (fun _ => 1)
        constructor
        · rw [zero_le_elim_iff]
          exact ⟨hy', fun _ => zero_le_one⟩
        constructor
        · sorry -- from `hAy'`
        · sorry -- from `hcy'`
      · intro ⟨y, hy, hAby, hcy⟩
        if last_zero : y (Sum.inr ()) = 0 then
          /-
          By `last_zero` we have...
          `hAby` : P.Aᵀ *ᵥ y ≤ 0
          `hcy`  : -P.c ⬝ᵥ y < 0
          -/
          exfalso
          unfold StandardLP.IsFeasible StandardLP.IsSolution at hP hD
          dsimp [StandardLP.dual] at hD
          -- I think we need to reach a contradiction with `hP` or `hD` here. How?!
          sorry
        else
          rw [←ne_eq] at last_zero
          use (y (Sum.inr ()))⁻¹ • y ∘ Sum.inl
          constructor; constructor
          · rw [Matrix.mulVec_smul]
            rw [inv_smul_le_iff_of_pos (lt_of_le_of_ne (hy (Sum.inr ())) last_zero.symm)]
            change hAby to -((-P.Aᵀ).fromRows (fun i _ => P.b i)ᵀ)ᵀ *ᵥ y ≤ 0
            rw [
              ←Sum.elim_comp_inl_inr y, ←Matrix.transpose_neg P.A,
              ←Matrix.transpose_fromColumns, Matrix.transpose_transpose,
              Matrix.neg_mulVec, Matrix.fromColumns_mulVec_sum_elim,
              neg_add, Matrix.neg_mulVec, neg_neg, add_neg_le_iff_le_add, zero_add
            ] at hAby
            convert hAby
            unfold Matrix.mulVec
            simp only [Matrix.dotProduct_pUnit, Function.comp_apply]
            ext i
            rw [Pi.smul_apply, smul_eq_mul, mul_comm]
          · apply smul_nonneg
            · apply inv_nonneg_of_nonneg
              exact hy (Sum.inr ())
            · intro i
              exact hy (Sum.inl i)
          · sorry -- from `hcy`
    · constructor
      · intro ⟨x', ⟨hAx', hx'⟩, hbx'⟩
        refine ⟨x', hx', ?_⟩
        rw [Matrix.fromRows_mulVec, elim_le_elim_iff]
        exact ⟨hAx', fun _ => hbx'⟩
      · intro ⟨x, hx, hPx⟩
        rw [Matrix.fromRows_mulVec, elim_le_elim_iff] at hPx
        exact ⟨x, ⟨hPx.left, hx⟩, hPx.right ()⟩

end inequalities_only


section equalities_only

/-- Linear program in the canonical form. Variables are of type `n`. Conditions are indexed by type `m`. -/
structure CanonicalLP (n m R : Type*) [Fintype n] [Fintype m] [OrderedSemiring R] where
  /-- Matrix of coefficients -/
  A : Matrix m n R
  /-- Right-hand side -/
  b : m → R
  /-- Objective function coefficients -/
  c : n → R

variable {n m R : Type*} [Fintype n] [Fintype m]

/-- Vector `x` is a solution to linear program `P` iff all entries of `x` are nonnegative and
its multiplication by matrix `A` from the left yields the vector `b`. -/
def CanonicalLP.IsSolution [OrderedSemiring R] (P : CanonicalLP n m R) (x : n → R) : Prop :=
  P.A *ᵥ x = P.b ∧ 0 ≤ x

/-- Linear program `P` is feasible iff there is a vector `x` that is a solution to `P`. -/
def CanonicalLP.IsFeasible [OrderedSemiring R] (P : CanonicalLP n m R) : Prop :=
  ∃ x : n → R, P.IsSolution x

/-- Linear program `P` reaches objective value `v` iff there is a solution `x` such that,
when its entries are elementwise multiplied by the costs (given by the vector `c`) and summed up,
the result is the value `v`. -/
def CanonicalLP.Reaches [OrderedSemiring R] (P : CanonicalLP n m R) (v : R) : Prop :=
  ∃ x : n → R, P.IsSolution x ∧ P.c ⬝ᵥ x = v

def CanonicalLP.toStandardLP [OrderedRing R] (P : CanonicalLP n m R) : StandardLP n (m ⊕ m) R :=
  StandardLP.mk
    (Matrix.fromRows P.A (-P.A))
    (Sum.elim P.b (-P.b))
    P.c

lemma CanonicalLP.toStandardLP_isSolution_iff [OrderedRing R] (P : CanonicalLP n m R) (x : n → R) :
    P.toStandardLP.IsSolution x ↔ P.IsSolution x := by
  constructor
  · intro hyp
    simp only [StandardLP.IsSolution, CanonicalLP.toStandardLP, Matrix.fromRows_mulVec] at hyp
    rw [elim_le_elim_iff] at hyp
    obtain ⟨⟨ineqPos, ineqNeg⟩, nonneg⟩ := hyp
    constructor
    · apply eq_of_le_of_le ineqPos
      intro i
      have almost : -((P.A *ᵥ x) i) ≤ -(P.b i)
      · specialize ineqNeg i
        rwa [Matrix.neg_mulVec] at ineqNeg
      rwa [neg_le_neg_iff] at almost
    · exact nonneg
  · intro hyp
    unfold CanonicalLP.toStandardLP
    unfold StandardLP.IsSolution
    obtain ⟨equ, nonneg⟩ := hyp
    constructor
    · rw [Matrix.fromRows_mulVec, elim_le_elim_iff]
      constructor
      · exact equ.le
      rw [Matrix.neg_mulVec]
      intro i
      show -((P.A *ᵥ x) i) ≤ -(P.b i)
      rw [neg_le_neg_iff]
      exact equ.symm.le i
    · exact nonneg

lemma CanonicalLP.toStandardLP_isFeasible_iff [OrderedRing R] (P : CanonicalLP n m R) :
    P.toStandardLP.IsFeasible ↔ P.IsFeasible := by
  constructor <;> intro ⟨x, hx⟩ <;> use x
  · rwa [CanonicalLP.toStandardLP_isSolution_iff] at hx
  · rwa [CanonicalLP.toStandardLP_isSolution_iff]

lemma CanonicalLP.toStandardLP_reaches_iff [OrderedRing R] (P : CanonicalLP n m R) (v : R) :
    P.toStandardLP.Reaches v ↔ P.Reaches v := by
  constructor <;> intro ⟨x, hx⟩ <;> use x
  · rwa [CanonicalLP.toStandardLP_isSolution_iff] at hx
  · rwa [CanonicalLP.toStandardLP_isSolution_iff]

end equalities_only
