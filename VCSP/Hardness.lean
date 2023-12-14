import VCSP.FractionalPolymorphisms
import VCSP.Expressibility
import Mathlib.Algebra.Order.SMul
import Mathlib.Data.Fin.VecNotation


@[simp]
abbrev Multiset.summap {α β : Type*} [AddCommMonoid β] (s : Multiset α) (f : α → β) : β :=
  (s.map f).sum


section better_notation

/-- Given `n : ℕ` and `l : List α`, print `List.take n l` as `l.take n` in Infoview. -/
@[app_unexpander List.take]
def List.take.unexpander : Lean.PrettyPrinter.Unexpander
  | `($_ $n $l) => `($(l).$(Lean.mkIdent `take) $n)
  | _ => throw ()

/-- Given `n : ℕ` and `l : List α`, print `List.drop n l` as `l.drop n` in Infoview. -/
@[app_unexpander List.drop]
def List.drop.unexpander : Lean.PrettyPrinter.Unexpander
  | `($_ $n $l) => `($(l).$(Lean.mkIdent `drop) $n)
  | _ => throw ()

/-- Given `p : α → Bool` and `l : List α`, print `List.takeWhile p l` as `l.takeWhile p` in Infoview. -/
@[app_unexpander List.takeWhile]
def List.takeWhile.unexpander : Lean.PrettyPrinter.Unexpander
  | `($_ $p $l) => `($(l).$(Lean.mkIdent `takeWhile) $p)
  | _ => throw ()

/-- Given `p : α → Bool` and `l : List α`, print `List.dropWhile p l` as `l.dropWhile p` in Infoview. -/
@[app_unexpander List.dropWhile]
def List.dropWhile.unexpander : Lean.PrettyPrinter.Unexpander
  | `($_ $p $l) => `($(l).$(Lean.mkIdent `dropWhile) $p)
  | _ => throw ()

/-- Given `f : α → β` and `l : List α`, print `List.map f l` as `l.map f` in Infoview. -/
@[app_unexpander List.map]
def List.map.unexpander : Lean.PrettyPrinter.Unexpander
  | `($_ $f $l) => `($(l).$(Lean.mkIdent `map) $f)
  | _ => throw ()

/-- Given `f : α → β` and `s : Multiset α`, print `Multiset.map f s` as `s.map f` in Infoview. -/
@[app_unexpander Multiset.map]
def Multiset.map.unexpander : Lean.PrettyPrinter.Unexpander
  | `($_ $f $s) => `($(s).$(Lean.mkIdent `map) $f)
  | _ => throw ()

attribute [pp_dot] List.length List.get List.sum Multiset.sum Multiset.summap
  Sigma.fst Sigma.snd
  ValuedCsp.Term.evalSolution ValuedCsp.Term.f ValuedCsp.Term.n ValuedCsp.Term.app
  FractionalOperation.size FractionalOperation.tt

macro "change " h:ident " to " t:term : tactic => `(tactic| change $t at $h:ident)

end better_notation


section push_higher

lemma univ_val_map_2x2 {α β : Type*} {f : (Fin 2 → α) → β} {a b c d : α} :
    Finset.univ.val.map (fun i => f (![![a, b], ![c, d]] i)) = [f ![a, b], f ![c, d]] :=
  rfl

lemma Multiset.sum_ofList_twice {M : Type*} [AddCommMonoid M] (x : M) :
    Multiset.sum ↑[x, x] = 2 • x := by
  simp [two_nsmul]

lemma column_of_2x2_left {α : Type*} (a b c d : α) :
    (fun i => ![![a, b], ![c, d]] i 0) = (fun i => ![a, c] i) := by
  ext i
  match i with
  | 0 => rfl
  | 1 => rfl

lemma column_of_2x2_right {α : Type*} (a b c d : α) :
    (fun i => ![![a, b], ![c, d]] i 1) = (fun i => ![b, d] i) := by
  ext i
  match i with
  | 0 => rfl
  | 1 => rfl

lemma Multiset.summap_singleton {α β : Type*} [AddCommMonoid β] (a : α) (f : α → β) :
    Multiset.summap {a} f = f a := by
  simp

lemma Multiset.summap_nsmul {α β : Type*} [AddCommMonoid β] (s : Multiset α) (f : α → β) (n : ℕ) :
    s.summap (fun a => n • f a) = n • s.summap f := by
  induction n with
  | zero => simp
  | succ n ih => simp [succ_nsmul, Multiset.sum_map_add, ih]

lemma Multiset.summap_summap_swap {α β γ : Type*} [AddCommMonoid γ]
    (A : Multiset α) (B : Multiset β) (f : α → β → γ) :
    A.summap (fun a => B.summap (fun b => f a b)) =
    B.summap (fun b => A.summap (fun a => f a b)) := by
  apply Multiset.sum_map_sum_map

end push_higher


variable {D C : Type*}

lemma nsmul_iInf [OrderedAddCommMonoidWithInfima C] (f : D → C) {n : ℕ} :
    n • iInf f = iInf (fun a => n • f a) := by
  sorry

lemma level1 [OrderedAddCommMonoid C] {Γ : ValuedCsp D C} {ι : Type*} (t : Γ.Term ι)
    {m : ℕ} (ω : FractionalOperation D m) (x : Fin m → (ι → D))
    (impr : t.f.AdmitsFractional ω) :
    m • (ω.tt (fun i : Fin m => x i ∘ t.app)).summap t.f ≤
    ω.size • Finset.univ.val.summap (fun i : Fin m => t.f (x i ∘ t.app)) :=
  impr (x · ∘ t.app)

lemma level2 [OrderedAddCommMonoid C] {Γ : ValuedCsp D C} {ι : Type*} (t : Γ.Term ι)
    {m : ℕ} (ω : FractionalOperation D m) (x : Fin m → (ι → D))
    (impr : t.f.AdmitsFractional ω) :
    m • (ω.tt (fun i : Fin m => x i)).summap t.evalSolution ≤
    ω.size • Finset.univ.val.summap (fun i : Fin m => t.evalSolution (x i)) := by
  convert level1 t ω x impr
  show
    (ω.tt (x ·)).summap (fun xᵢ => t.f (xᵢ ∘ t.app)) =
    (ω.tt (x · ∘ t.app)).summap t.f
  convert_to
    Multiset.sum ((ω.tt (x ·)).map (fun xᵢ => t.f (fun i => xᵢ (t.app i)))) =
    Multiset.sum ((ω.tt (x · ∘ t.app)).map t.f)
  apply congr_arg
  show
    (ω.tt (x ·)).map (fun xᵢ : ι → D => t.f (fun i : Fin t.n => xᵢ (t.app i))) =
    (ω.tt (x · ∘ t.app)).map t.f
  sorry

lemma level3 [OrderedAddCommMonoid C] {Γ : ValuedCsp D C} {ι : Type*} (I : Γ.Instance ι)
    {m : ℕ} (ω : FractionalOperation D m) (x : Fin m → (ι → D))
    (frpo : ω.IsFractionalPolymorphismFor Γ) :
    m • (ω.tt x).summap I.evalSolution ≤
    ω.size • Finset.univ.val.summap (fun i : Fin m => I.evalSolution (x i)) := by
  show
    m • (ω.tt x).summap (fun yᵢ => I.summap (fun t => t.evalSolution yᵢ)) ≤
    ω.size • Finset.univ.val.summap (fun i => I.summap (fun t => t.evalSolution (x i)))
  rw [Multiset.summap_summap_swap _ I, Multiset.summap_summap_swap _ I]
  rw [←Multiset.summap_nsmul, ←Multiset.summap_nsmul]
  apply Multiset.sum_map_le_sum_map
  intro t _
  apply level2
  exact frpo ⟨t.n, t.f⟩ t.inΓ

lemma level4 [OrderedAddCommMonoid C] {Γ : ValuedCsp D C} {ι μ : Type*} (I : Γ.Instance (ι ⊕ μ))
    {m : ℕ} (ω : FractionalOperation D m) (x : Fin m → (ι → D)) (z : μ → D)
    (frpo : ω.IsFractionalPolymorphismFor Γ) :
    m • (ω.tt x).summap (I.evalPartial · z) ≤
    ω.size • Finset.univ.val.summap (fun i : Fin m => I.evalPartial (x i) z) := by
  show
    m • (ω.tt x).summap (fun yᵢ => I.summap (fun t => t.evalSolution (Sum.elim yᵢ z))) ≤
    ω.size • Finset.univ.val.summap (fun i => I.summap (fun t => t.evalSolution (Sum.elim (x i) z)))
  rw [Multiset.summap_summap_swap _ I, Multiset.summap_summap_swap _ I]
  rw [←Multiset.summap_nsmul, ←Multiset.summap_nsmul]
  apply Multiset.sum_map_le_sum_map
  intro t _
  sorry

lemma level5 [OrderedAddCommMonoidWithInfima C] {Γ : ValuedCsp D C} {ι μ : Type*} (I : Γ.Instance (ι ⊕ μ))
    {m : ℕ} (ω : FractionalOperation D m) (x : Fin m → (ι → D))
    (frpo : ω.IsFractionalPolymorphismFor Γ) :
    m • (ω.tt x).summap I.evalMinimize ≤
    ω.size • Finset.univ.val.summap (fun i : Fin m => I.evalMinimize (x i)) := by
  sorry


section messy_af

example [CompleteSemilatticeInf C] (a b c d : C) (hac : a ≤ c) (hbd : b ≤ d) :
    sInf ({a, b} : Set C) ≤ sInf ({c, d} : Set C) := by
  have hsa : sInf ({a, b} : Set C) ≤ a
  · exact sInf_le (Set.mem_insert a {b})
  have hsb : sInf ({a, b} : Set C) ≤ b
  · rw [Set.pair_comm]
    exact sInf_le (Set.mem_insert b {a})
  have hsc : sInf ({a, b} : Set C) ≤ c
  · exact hsa.trans hac
  have hsd : sInf ({a, b} : Set C) ≤ d
  · exact hsb.trans hbd
  aesop

example [OrderedAddCommMonoidWithInfima C] (a a' b b' c c' d d' : C)
    (hac : a ≤ c) (hbd : b ≤ d) (hac' : a' ≤ c') (hbd' : b' ≤ d') :
    sInf {a, b} + sInf {a', b'} ≤ sInf {c, d} + sInf {c', d'} := by
  have hsc : sInf ({a, b} : Set C) ≤ c
  · exact (sInf_le (Set.mem_insert a {b})).trans hac
  have hsd : sInf ({a, b} : Set C) ≤ d
  · rw [Set.pair_comm]
    exact (sInf_le (Set.mem_insert b {a})).trans hbd
  have hsc' : sInf ({a', b'} : Set C) ≤ c'
  · exact (sInf_le (Set.mem_insert a' {b'})).trans hac'
  have hsd' : sInf ({a', b'} : Set C) ≤ d'
  · rw [Set.pair_comm]
    exact (sInf_le (Set.mem_insert b' {a'})).trans hbd'
  apply add_le_add <;> simp_all

example [OrderedAddCommMonoidWithInfima C] (a b c d : Fin 9 → C) (hac : a ≤ c) (hbd : b ≤ d) :
    (Finset.univ.val.map (fun i : Fin 9 => sInf {a i, b i})).sum ≤
    (Finset.univ.val.map (fun i : Fin 9 => sInf {c i, d i})).sum := by
  apply Multiset.sum_map_le_sum_map
  intro i _
  have hsci : sInf {a i, b i} ≤ c i
  · exact (sInf_le (Set.mem_insert (a i) {b i})).trans (hac i)
  have hsdi : sInf {a i, b i} ≤ d i
  · rw [Set.pair_comm]
    exact (sInf_le (Set.mem_insert (b i) {a i})).trans (hbd i)
  simp [hsci, hsdi]

example [CompleteLattice C] (f g : D → C) (hfg : ∀ x : D, f x ≤ g x) :
    sInf { f x | x : D } ≤ sInf { g x | x : D } := by
  simp only [le_sInf_iff, Set.mem_setOf_eq, forall_exists_index, forall_apply_eq_imp_iff]
  intro a
  have hfa : f a ∈ { f x | x : D }
  · use a
  exact sInf_le_of_le hfa (hfg a)

example [OrderedAddCommMonoidWithInfima C] (n : ℕ) (a b : Fin n → D → C) (hab : a ≤ b) :
    (Finset.univ.val.map (fun i : Fin n => sInf { a i j | j : D })).sum ≤
    (Finset.univ.val.map (fun i : Fin n => sInf { b i j | j : D })).sum := by
  apply Multiset.sum_map_le_sum_map
  intro i _
  simp only [le_sInf_iff, Set.mem_setOf_eq, forall_exists_index, forall_apply_eq_imp_iff]
  intro x
  have haix : a i x ∈ { a i j | j : D }
  · use x
  exact sInf_le_of_le haix (hab i x)

example [OrderedAddCommMonoidWithInfima C] (n : ℕ) (a b c d : Fin n → D → C)
    (hac : a ≤ c) (hbd : b ≤ d) :
    (Finset.univ.val.map (fun i : Fin n => sInf { a i j + b i j | j : D })).sum ≤
    (Finset.univ.val.map (fun i : Fin n => sInf { c i j + d i j | j : D })).sum := by
  apply Multiset.sum_map_le_sum_map
  intro i _
  simp only [le_sInf_iff, Set.mem_setOf_eq, forall_exists_index, forall_apply_eq_imp_iff]
  intro x
  have habix : a i x + b i x ∈ { a i j + b i j | j : D }
  · use x
  apply sInf_le_of_le habix
  apply add_le_add
  · apply hac
  · apply hbd

example [OrderedAddCommMonoidWithInfima C] (n : ℕ) (x : Fin n → D → Multiset D)
    (f g : D → C) (hfg : f ≤ g) :
    (Finset.univ.val.map (fun i : Fin n => sInf { ((x i j).map f).sum | j : D })).sum ≤
    (Finset.univ.val.map (fun i : Fin n => sInf { ((x i j).map g).sum | j : D })).sum := by
  apply Multiset.sum_map_le_sum_map
  intro i _
  simp only [le_sInf_iff, Set.mem_setOf_eq, forall_exists_index, forall_apply_eq_imp_iff]
  intro d
  have hxidf : ((x i d).map f).sum ∈ { ((x i j).map f).sum | j : D }
  · use d
  apply sInf_le_of_le hxidf
  apply Multiset.sum_map_le_sum_map
  intro e _
  exact hfg e

lemma sInf_summap_le_sInf_summap [OrderedAddCommMonoidWithInfima C] {μ : Type} {f g : D → μ → C}
    (hfg : ∀ d : D, ∀ z : μ, f d z ≤ g d z) (S : Multiset D) :
    sInf { S.summap (f · z) | z : μ } ≤
    sInf { S.summap (g · z) | z : μ } := by
  apply sInf_le_sInf_of_forall_exists_le
  intro x xin
  rw [Set.mem_setOf_eq] at xin
  obtain ⟨z, hxz⟩ := xin
  use S.summap (f · z)
  convert_to S.summap (f · z) ≤ x
  · simp
  rw [←hxz]
  apply Multiset.sum_map_le_sum_map
  intros
  apply hfg

lemma sInf_summap_le_summap_sInf_summap [OrderedAddCommMonoidWithInfima C] {μ : Type}
    {f : D → μ → C} {g : D → D → μ → C} {X : Multiset D}
    (hfg : ∀ d : D, ∀ z : μ, f d z ≤ X.summap (fun x : D => g x d z)) (S : Multiset D) :
    sInf { S.summap (f · z) | z : μ } ≤
    X.summap (fun x : D => sInf { S.summap (g x · z) | z : μ }) := by
  sorry  -- Does not hold either!

lemma nsmul_sInf_summap_le_summap_sInf_summap [OrderedAddCommMonoidWithInfima C] {μ : Type}
    {f : D → μ → C} {g : D → D → μ → C} {X : Multiset D}
    (hfg : ∀ d : D, ∀ z : μ,
        Multiset.card.toFun X • f d z ≤ X.summap (fun x : D => g x d z))
    (S : Multiset D) :
    Multiset.card.toFun X • sInf { S.summap (f · z) | z : μ } ≤
    X.summap (fun x : D => sInf { S.summap (g x · z) | z : μ }) := by
  sorry  -- Does not hold either!!

-- If we have homomorphism `h` in place of fractional polymorphism `ω` ...
example [OrderedAddCommMonoidWithInfima C] {Γ : ValuedCsp D C} {ι μ : Type} {I : Γ.Instance (ι ⊕ μ)}
    {h : D → D} (hhh : ∀ f ∈ Γ, ∀ x : Fin f.fst → D, f.snd (fun i => h (x i)) ≤ f.snd x) :
  ∀ x : ι → D,
    sInf { I.summap (fun t : Γ.Term (ι ⊕ μ) => t.f (Sum.elim (fun i => h (x i)) z ∘ t.app)) | z : μ → D } ≤
    sInf { I.summap (fun t : Γ.Term (ι ⊕ μ) => t.f (Sum.elim x z ∘ t.app)) | z : μ → D } := by
  intro x
  apply sInf_le_sInf_of_forall_exists_le
  intro c cin
  rw [Set.mem_setOf_eq] at cin
  obtain ⟨z, hcz⟩ := cin
  simp only [Set.mem_setOf_eq, exists_exists_eq_and]
  use (h ∘ z)
  rw [←hcz]
  apply Multiset.sum_map_le_sum_map
  intro t _
  convert hhh ⟨t.n, t.f⟩ t.inΓ (Sum.elim x z ∘ t.app) with j
  show (Sum.elim (h ∘ x) (h ∘ z)) (t.app j) = (h ∘ Sum.elim x z) (t.app j)
  apply congr_fun
  exact (Sum.comp_elim h x z).symm

lemma FractionalOperation.tt_singleton {m n : ℕ} {ω : FractionalOperation D m} (x : Fin m → Fin n → D)
    {g : (Fin m → D) → D} (singleto : ω = {g}) :
    ω.tt x = {fun i => g (Function.swap x i)} := by
  unfold FractionalOperation.tt
  rw [singleto, Multiset.map_singleton]

-- If we have multimorphism `ω` in place of fractional polymorphism `ω` ...
example [OrderedAddCommMonoidWithInfima C] {Γ : ValuedCsp D C}
    {m : ℕ} {ω : FractionalOperation D m} (g : (Fin m → D) → D) (singleto : ω = {g})
    (frpo : ω.IsFractionalPolymorphismFor Γ) :
    ω.IsFractionalPolymorphismFor Γ.expressivePower := by
  intro f hf
  rw [ValuedCsp.expressivePower, Set.mem_setOf_eq] at hf
  rcases hf with ⟨n, μ, I, rfl⟩
  unfold FractionalOperation.IsFractionalPolymorphismFor at frpo
  unfold Function.AdmitsFractional at frpo
  intro x
  rw [Multiset.smul_sum, Multiset.map_map, Multiset.smul_sum, Multiset.map_map]
  convert_to -- this is safe
    (ω.tt x).summap (fun y : Fin n → D =>
        sInf { I.summap (fun t : Γ.Term (Fin n ⊕ μ) => m • t.f (Sum.elim y z ∘ t.app)) | z : μ → D }) ≤
    Finset.univ.val.summap (fun i : Fin m =>
        sInf { I.summap (fun t : Γ.Term (Fin n ⊕ μ) => ω.size • t.f (Sum.elim (x i) z ∘ t.app)) | z : μ → D })
  · sorry
  · sorry
  have part_ineq :
    ∀ f₁ ∈ Γ, ∀ x₁ : Fin m → Fin f₁.fst → D,
      (ω.tt x₁).summap (fun v : Fin f₁.fst → D => m • f₁.snd v) ≤
      Finset.univ.val.summap (fun i : Fin m => ω.size • f₁.snd (x₁ i))
  · convert frpo <;> apply Multiset.summap_nsmul
  have size1 : ω.size = 1
  · rw [singleto]
    rfl
  rw [FractionalOperation.tt_singleton _ singleto]
  simp_rw [FractionalOperation.tt_singleton _ singleto] at part_ineq
  rw [singleto] at *
  simp_rw [size1, one_smul, Multiset.summap_singleton] at part_ineq ⊢
  clear frpo singleto ω size1
  change part_ineq to
    ∀ f₁ ∈ Γ, ∀ x₁ : Fin m → Fin f₁.fst → D,
      m • f₁.snd (fun i => g (Function.swap x₁ i)) ≤
      Finset.univ.val.summap (fun i : Fin m => f₁.snd (x₁ i))
  show
    sInf { I.summap (fun t => m • t.f (Sum.elim (fun i => g (Function.swap x i)) z ∘ t.app)) | z : μ → D } ≤
    Finset.univ.val.summap (fun i : Fin m =>
        sInf { I.summap (fun t : Γ.Term (Fin n ⊕ μ) => t.f (Sum.elim (x i) z ∘ t.app)) | z : μ → D })
  convert_to -- this is sus
    sInf { I.summap (fun t => m • t.f (Sum.elim (fun i => g (Function.swap x i)) z ∘ t.app)) | z : μ → D } ≤
    sInf { Finset.univ.val.summap (fun i : Fin m =>
        I.summap (fun t : Γ.Term (Fin n ⊕ μ) => t.f (Sum.elim (x i) z ∘ t.app))) | z : μ → D }
  · sorry
  apply sInf_le_sInf_of_forall_exists_le
  simp only [Set.mem_setOf_eq, exists_exists_eq_and, forall_exists_index, forall_apply_eq_imp_iff]
  intro c
  show
    ∃ a : μ → D,
      I.summap (fun t => m • t.f (Sum.elim (fun i => g (Function.swap x i)) a ∘ t.app)) ≤
      Finset.univ.val.summap (fun i => I.summap (fun t => t.f (Sum.elim (x i) c ∘ t.app)))
  convert_to -- this seems OK
    ∃ a : μ → D,
      I.summap (fun t => m • t.f (Sum.elim (fun i => g (Function.swap x i)) a ∘ t.app)) ≤
      I.summap (fun t => Finset.univ.val.summap (fun i => t.f (Sum.elim (x i) c ∘ t.app)))
  · sorry
  -- use c
  -- use (fun k => g (fun _ : Fin m => c k))
  have z : μ → D := sorry
  use z
  apply Multiset.sum_map_le_sum_map
  intro t tin
  /-show
    m • t.f (Sum.elim (fun i => g (Function.swap x i)) c ∘ t.app) ≤
    Finset.univ.val.summap (fun i : Fin m => t.f (Sum.elim (x i) c ∘ t.app))
  specialize part_ineq ⟨t.n, t.f⟩ t.inΓ (fun i => Sum.elim (x i) c ∘ t.app)
  change part_ineq to
    m • t.f (fun i => g (Function.swap (fun i => Sum.elim (x i) c ∘ t.app) i)) ≤
    Finset.univ.val.summap (fun i : Fin m => t.f (Sum.elim (x i) c ∘ t.app))
  convert part_ineq with j
  show (Sum.elim (fun i => g (fun k => x k i)) c) (t.app j) = g (fun k => (fun i => Sum.elim (x i) c) k (t.app j))
  show (Sum.elim (fun i => g (fun k => x k i)) _) (t.app j) = g (fun k => (fun i => Sum.elim (x i) c) k (t.app j))
  show (Sum.elim (fun i => g (fun k => x k i)) _) (t.app j) = g (fun k => ((fun i =>
    @Sum.elim (Fin I.expresses.fst) μ D (x i) c) : (Fin m → Fin I.expresses.fst ⊕ μ → D))
    k (t.app j))
  show (Sum.elim (fun i => g (fun k => x k i)) _) (t.app j) = g (fun k => (((fun i =>
    @Sum.elim (Fin I.expresses.fst) μ D (x i) c) k) : (Fin I.expresses.fst ⊕ μ → D)) (t.app j))
  show (Sum.elim (fun i => g (fun k => x k i)) _) (t.app j) = g (fun k => (((fun i =>
    Sum.elim (x i) c) k) : (Fin I.expresses.fst ⊕ μ → D)) (t.app j))
  show (Sum.elim (fun i => g (fun k => x k i)) _) (t.app j) = g (fun k => ((fun i =>
    Sum.elim ((x i) k) (c k)) : (Fin I.expresses.fst ⊕ μ → D)) (t.app j))-/
  /-show
    m • t.f (Sum.elim (fun i => g (Function.swap x i)) (fun k : μ => g (fun _ => c k)) ∘ t.app) ≤
    Finset.univ.val.summap (fun i : Fin m => t.f (Sum.elim (x i) c ∘ t.app))
  specialize part_ineq ⟨t.n, t.f⟩ t.inΓ (fun i => Sum.elim (x i) (fun k => g (fun _ => c k)) ∘ t.app)
  change part_ineq to
    m • t.f (fun j : Fin t.n => g (Function.swap (fun i : Fin m => Sum.elim (x i) (fun k : μ => g (fun _ => c k)) ∘ t.app) j)) ≤
    Finset.univ.val.summap (fun i : Fin m => t.f (Sum.elim (x i) (fun k : μ => g (fun _ => c k)) ∘ t.app))-/
  show
    m • t.f (Sum.elim (fun i => g (Function.swap x i)) z ∘ t.app) ≤
    Finset.univ.val.summap (fun i : Fin m => t.f (Sum.elim (x i) c ∘ t.app))
  specialize part_ineq ⟨t.n, t.f⟩ t.inΓ (fun i => Sum.elim (x i) z ∘ t.app)
  change part_ineq to
    m • t.f (fun i => g (Function.swap (fun i => Sum.elim (x i) z ∘ t.app) i)) ≤
    Finset.univ.val.summap (fun i : Fin m => t.f (Sum.elim (x i) z ∘ t.app))
  sorry

end messy_af


lemma FractionalOperation.IsFractionalPolymorphismFor.expressivePower
    [OrderedAddCommMonoidWithInfima C] {Γ : ValuedCsp D C}
    {m : ℕ} {ω : FractionalOperation D m}
    (frpo : ω.IsFractionalPolymorphismFor Γ) :
    ω.IsFractionalPolymorphismFor Γ.expressivePower := by
  intro f hf
  rw [ValuedCsp.expressivePower, Set.mem_setOf_eq] at hf
  rcases hf with ⟨n, μ, I, rfl⟩
  intro x
  apply level5
  exact frpo

/-- Function `f` has Max-Cut property at labels `a` and `b` when `argmin f` is exactly:
   `{ ![a, b] , ![b, a] }` -/
def Function.HasMaxCutPropertyAt [OrderedAddCommMonoid C] (f : (Fin 2 → D) → C) (a b : D) : Prop :=
  f ![a, b] = f ![b, a] ∧
  ∀ x y : D, f ![a, b] ≤ f ![x, y] ∧ (f ![a, b] = f ![x, y] → a = x ∧ b = y ∨ a = y ∧ b = x)

/-- Function `f` has Max-Cut property at some two non-identical labels. -/
def Function.HasMaxCutProperty [OrderedAddCommMonoid C] (f : (Fin 2 → D) → C) : Prop :=
  ∃ a b : D, a ≠ b ∧ f.HasMaxCutPropertyAt a b

def ValuedCsp.CanExpressMaxCut [OrderedAddCommMonoidWithInfima C] {Γ : ValuedCsp D C} : Prop :=
  ∃ f : (Fin 2 → D) → C, ⟨2, f⟩ ∈ Γ.expressivePower ∧ f.HasMaxCutProperty

lemma Function.HasMaxCutProperty.forbids_commutativeFP [OrderedCancelAddCommMonoid C]
    {f : (Fin 2 → D) → C} (mcf : f.HasMaxCutProperty)
    {ω : FractionalOperation D 2} (valid : ω.IsValid) (symmega : ω.IsSymmetric) :
    ¬ f.AdmitsFractional ω := by
  intro contr
  rcases mcf with ⟨a, b, hab, mcfab⟩
  specialize contr ![![a, b], ![b, a]]
  rw [univ_val_map_2x2, ← mcfab.left, Multiset.sum_ofList_twice] at contr
  have sharp :
    2 • ((ω.tt ![![a, b], ![b, a]]).map (fun _ => f ![a, b])).sum <
    2 • ((ω.tt ![![a, b], ![b, a]]).map (fun r => f r)).sum
  · have rows_lt : ∀ r ∈ (ω.tt ![![a, b], ![b, a]]), f ![a, b] < f r
    · intro r rin
      rw [FractionalOperation.tt, Multiset.mem_map] at rin
      rcases rin with ⟨o, in_omega, eq_r⟩
      rw [show r = ![r 0, r 1] from List.ofFn_inj.mp rfl]
      apply lt_of_le_of_ne (mcfab.right (r 0) (r 1)).left
      intro equ
      have asymm : r 0 ≠ r 1
      · rcases (mcfab.right (r 0) (r 1)).right equ with ⟨ha0, hb1⟩ | ⟨ha1, hb0⟩
        · rw [ha0, hb1] at hab
          exact hab
        · rw [ha1, hb0] at hab
          exact hab.symm
      apply asymm
      rw [← eq_r]
      show o (fun j => ![![a, b], ![b, a]] j 0) = o (fun j => ![![a, b], ![b, a]] j 1)
      rw [column_of_2x2_left, column_of_2x2_right]
      exact symmega ![a, b] ![b, a] (List.Perm.swap b a []) o in_omega
    have half_sharp :
      ((ω.tt ![![a, b], ![b, a]]).map (fun _ => f ![a, b])).sum <
      ((ω.tt ![![a, b], ![b, a]]).map (fun r => f r)).sum
    · apply Multiset.sum_lt_sum
      · intro r rin
        exact le_of_lt (rows_lt r rin)
      · obtain ⟨g, _⟩ := valid.contains
        use fun i => g ((Function.swap ![![a, b], ![b, a]]) i)
        constructor
        · simp [FractionalOperation.tt]
          use g
        · apply rows_lt
          simp [FractionalOperation.tt]
          use g
    rw [two_nsmul, two_nsmul]
    exact add_lt_add half_sharp half_sharp
  have impos : 2 • (ω.map (fun _ => f ![a, b])).sum < ω.size • 2 • f ![a, b]
  · convert lt_of_lt_of_le sharp contr
    simp [FractionalOperation.tt, Multiset.map_map]
  have rhs_swap : ω.size • 2 • f ![a, b] = 2 • ω.size • f ![a, b]
  · apply nsmul_left_comm
  have distrib : (ω.map (fun _ => f ![a, b])).sum = ω.size • f ![a, b]
  · simp
  rw [rhs_swap, distrib] at impos
  exact ne_of_lt impos rfl

theorem ValuedCsp.CanExpressMaxCut.forbids_commutativeFP [OrderedCancelAddCommMonoidWithInfima C]
    {Γ : ValuedCsp D C} (expressMC : Γ.CanExpressMaxCut)
    {ω : FractionalOperation D 2} (valid : ω.IsValid) :
    ¬ ω.IsSymmetricFractionalPolymorphismFor Γ := by
  rintro ⟨frpol, symme⟩
  rcases expressMC with ⟨f, fin, fmc⟩
  apply fmc.forbids_commutativeFP valid symme
  exact frpol.expressivePower ⟨2, f⟩ fin
