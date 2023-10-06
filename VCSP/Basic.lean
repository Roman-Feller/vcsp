import Mathlib.Algebra.Order.Monoid.Defs
import Mathlib.Data.Fin.VecNotation

/-!

# General-Valued Constraint Satisfaction Problems

General-Valued CSP is a very broad class of problems in discrete optimization.
General-Valued CSP subsumes Min-Cost-Hom (including 3-SAT for example) and Finite-Valued CSP.

## Main definitions
* `ValuedCspTemplate`: A VCSP template; fixes a domain, a codomain, and allowed cost functions.
* `ValuedCspTerm`: One summand in a VCSP instance; calls a concrete function from given template.
* `ValuedCspTerm.evalSolution`: An evaluation of the VCSP term for given solution.
* `ValuedCspInstance`: An instance of a VCSP problem over given template.
* `ValuedCspInstance.evalSolution`: An evaluation of the VCSP instance for given solution.
* `ValuedCspInstance.optimumSolution`: Is given solution a minimum of the VCSP instance?

-/

def n1ary_of_unary {α β : Type _} (f : α → β) : (Fin 1 → α) → β :=
  fun a => f (a 0)

def n2ary_of_binary {α β : Type _} (f : α → α → β) : (Fin 2 → α) → β :=
  fun a => f (a 0) (a 1)

/-- A template for a valued CSP problem with costs in `C`. -/
structure ValuedCspTemplate (C : Type _) [LinearOrderedAddCommMonoid C] where
  /-- Domain of "labels" -/
  D : Type
  /-- Cost functions from `D^k` to `C` for any `k` -/
  F : Set (Σ (k : ℕ), (Fin k → D) → C)

variable {C : Type _} [LinearOrderedAddCommMonoid C]

/-- A term in a valued CSP instance over the template `Γ`. -/
structure ValuedCspTerm (Γ : ValuedCspTemplate C) (ι : Type _) where
  /-- Arity of the function -/
  k : ℕ
  /-- Which cost function is instantiated -/
  f : (Fin k → Γ.D) → C
  /-- The cost function comes from the template -/
  inΓ : ⟨k, f⟩ ∈ Γ.F
  /-- Which variables are plugged as arguments to the cost function -/
  app : Fin k → ι

def valuedCspTerm_of_unary {Γ : ValuedCspTemplate C} {ι : Type _} {f₁ : Γ.D → C}
    (ok : ⟨1, n1ary_of_unary f₁⟩ ∈ Γ.F) (i : ι) : ValuedCspTerm Γ ι :=
  ⟨1, n1ary_of_unary f₁, ok, ![i]⟩

def valuedCspTerm_of_binary {Γ : ValuedCspTemplate C} {ι : Type _} {f₂ : Γ.D → Γ.D → C}
    (ok : ⟨2, n2ary_of_binary f₂⟩ ∈ Γ.F) (i j : ι) : ValuedCspTerm Γ ι :=
  ⟨2, n2ary_of_binary f₂, ok, ![i, j]⟩

/-- Evaluation of a `Γ` term `t` for given solution `x`. -/
def ValuedCspTerm.evalSolution {Γ : ValuedCspTemplate C} {ι : Type _}
    (t : ValuedCspTerm Γ ι) (x : ι → Γ.D) : C :=
  t.f (x ∘ t.app)

/-- A valued CSP instance over the template `Γ` with variables indexed by `ι`.-/
def ValuedCspInstance (Γ : ValuedCspTemplate C) (ι : Type _) : Type :=
  List (ValuedCspTerm Γ ι)

/-- Evaluation of a `Γ` instance `I` for given solution `x`. -/
def ValuedCspInstance.evalSolution {Γ : ValuedCspTemplate C} {ι : Type _}
    (I : ValuedCspInstance Γ ι) (x : ι → Γ.D) : C :=
  (I.map (fun t => t.evalSolution x)).sum

/-- Condition for `x` being an optimum solution (min) to given `Γ` instance `I`.-/
def ValuedCspInstance.optimumSolution {Γ : ValuedCspTemplate C} {ι : Type _}
    (I : ValuedCspInstance Γ ι) (x : ι → Γ.D) : Prop :=
  ∀ y : ι → Γ.D, I.evalSolution x ≤ I.evalSolution y
