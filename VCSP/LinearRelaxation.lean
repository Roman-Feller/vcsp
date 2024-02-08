import VCSP.Hardness
import VCSP.LinearProgramming
import Mathlib.Data.Multiset.Fintype


variable
  {D : Type} [Nonempty D] [Fintype D] [DecidableEq D]
  {ι : Type} [Nonempty ι] [Fintype ι] [DecidableEq ι]
  {Γ : ValuedCSP D ℚ} [DecidableEq (Γ.Term ι)]

def ValuedCSP.Instance.LPvars (I : Γ.Instance ι) : Type :=
  (Σ t : I, (Fin t.fst.n → D)) ⊕ (ι × D)

def ValuedCSP.Instance.LPcons (I : Γ.Instance ι) : Type :=
  (Σ t : I, (Fin t.fst.n × D)) ⊕ ι ⊕ LPvars I

/-
For all `⟨t, j, a⟩` in `(Σ t ∈ I, Fin t.n × D)`, the sum of all |D| ^ (t.n - 1)
  `Sum.inl ⟨t, (x : Fin t.n → D | x j = a)⟩` must be equal to `Sum.inr (t.app j, a)`.
For all `i` in `ι`, the sum of all |D| `Sum.inr (i, _)` must be `1`.
Each `v` in `LPvars I` must be between `0` and `1`.

Ideally (--> tight relaxation)...
For each `i` in `ι`, there is exactly one `a` in `D` where
  `Sum.inr (i, a)` is `1` and all other `Sum.inr (i, _)` are `0`.
For all `⟨t, j⟩` in `(Σ t ∈ I, Fin t.n)`:
  · If `Sum.inr (t.app j, a)` is `0` then all `Sum.inl ⟨t, (x : Fin t.n → D | x j = a)⟩` are `0`.
  · If `Sum.inr (t.app j, a)` is `1` then there is exactly one `x : Fin t.n → D | x j = a` where
    `Sum.inl ⟨t, x⟩` is `1` and all other `Sum.inl ⟨t, (x : Fin t.n → D | x j = a)⟩` are `0`.
-/

def ValuedCSP.Instance.LPrelax (I : Γ.Instance ι)
     -- TODO the following three must be inferred automatically !!!
    [Fintype I.LPvars] [DecidableEq (I.LPvars)] [Fintype I.LPcons] :
    StandardLP I.LPcons I.LPvars ℚ :=
  StandardLP.mk
    (Sum.elim
      (fun ⟨⟨cₜ, _⟩, cᵢ, cₐ⟩ => Sum.elim
        (fun ⟨⟨t, _⟩, x⟩ =>
          if ht : cₜ.n = t.n
          then if x (Fin.cast ht cᵢ) = cₐ then 1 else 0
          else 0)
        (fun ⟨i, a⟩ => if cₜ.app cᵢ = i ∧ cₐ = a then -1 else 0))
      (Sum.elim
        (fun cᵢ => Sum.elim
          (fun _ => 0)
          (fun ⟨i, _⟩ => if cᵢ = i then 1 else 0))
        (fun cᵥ => fun v => if cᵥ = v then 1 else 0)))
    (Sum.elim
      (fun _ => 0)
      (fun _ => 1))
    (Sum.elim
      (fun ⟨⟨t, _⟩, x⟩ => t.f x)
      (fun _ => 0))

open Matrix

lemma sumType_zeroFun_dotProduct {α β : Type} [Fintype α] [Fintype β]
    {f g : α → ℚ} {g' : β → ℚ} :
    (Sum.elim f 0) ⬝ᵥ (Sum.elim g g') = f ⬝ᵥ g := by
  rw [Matrix.sum_elim_dotProduct_sum_elim, zero_dotProduct, add_zero]

theorem ValuedCSP.Instance.LPrelax_solution (I : Γ.Instance ι)
     -- TODO the following three must be inferred automatically !!!
    [Fintype I.LPvars] [DecidableEq (I.LPvars)] [Fintype I.LPcons]
    (x : ι → D) :
    I.LPrelax.Reaches (I.evalSolution x) := by
  let s : I.LPvars → ℚ :=
    Sum.elim
      (fun ⟨⟨t, _⟩, (v : (Fin t.n → D))⟩ => if ∀ i : Fin t.n, v i = x (t.app i) then 1 else 0)
      (fun ⟨i, d⟩ => if x i = d then 1 else 0)
  use s
  constructor
  · simp [StandardLP.IsSolution, ValuedCSP.Instance.LPrelax]
    constructor
    · intro c
      cases c with
      | inl val =>
        obtain ⟨⟨⟨n, f, _, ξ⟩, _⟩, cᵢ, cₐ⟩ := val
        show _ ≤ 0
        sorry
      | inr val =>
        show _ ≤ 1
        cases val with
        | inl cᵢ =>
          sorry
        | inr val =>
          cases val with
          | inl val =>
            obtain ⟨cₜ, cᵥ⟩ := val
            sorry
          | inr val =>
            obtain ⟨cᵢ, cₐ⟩ := val
            sorry
    · intro v
      cases v with
      | inl => aesop
      | inr => aesop
  · simp [ValuedCSP.Instance.LPrelax, ValuedCSP.Instance.evalSolution]
    trans
    · convert sumType_zeroFun_dotProduct <;> exact inferInstance
    sorry
