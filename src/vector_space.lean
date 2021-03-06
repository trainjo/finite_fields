import set_theory.cardinal
import linear_algebra.dimension

universes u v

namespace finsupp

open finset

--finsupp or fintype
def equiv_fun {α : Type u} {β : Type v} [decidable_eq α] [has_zero α] [h : fintype β] :
(β →₀ α) ≃ (β → α) :=
{ to_fun := finsupp.to_fun,
  inv_fun := λ f, finsupp.mk (finset.filter (λ a, f a ≠ 0) h.elems) f
    (assume a, by rw[mem_filter]; exact and_iff_right (fintype.complete a)),
  left_inv := λ f, finsupp.ext (λ _, rfl),
  right_inv := λ f, rfl }

variables {α : Type u} {β : Type v}
variables [decidable_eq α]
variables [decidable_eq β] [add_comm_group β]

variable (s : finset α)

--with map_domain
lemma map_domain_apply {α₁ α₂ : Type*} [decidable_eq α₁] [decidable_eq α₂]
(v : α₁ → α₂) (f : α₁ →₀ β) (h : function.injective v) {a : α₁} :
(map_domain v f) (v a) = f a := show (f.sum $ λ x, single (v x)) (v a) = f a,
begin
  rw[←sum_single f],
  simp,
  apply sum_congr, refl,
  intros,
  simp[single_apply, function.injective.eq_iff h],
  congr
end

--subtype_domain
lemma subtype_domain_left_inv (p : α → Prop) [d : decidable_pred p] (f : α →₀ β) (h : ∀ a ∈ f.support, p a) :
map_domain subtype.val (subtype_domain p f) = f :=
finsupp.ext $ λ a, match d a with
| is_true  (hp : p a)  := by rw[←subtype.coe_mk _ hp];
  exact map_domain_apply _ _ subtype.val_injective
| is_false (hp : ¬p a) :=
  have a ∉ f.support, from mt (h a) hp,
  have h0 : f a = 0, from of_not_not $ mt ((f.mem_support_to_fun a).mpr) this,
  begin
    rw[h0],
    apply (not_mem_support_iff).mp,
    apply mt (mem_of_subset map_domain_support),
    simp,
    assume x _ hfx hxa,
    exact absurd h0 (hxa ▸ hfx)
  end
end

--subtype domain
lemma subtype_domain_right_inv (p : α → Prop) [decidable_pred p] (f : subtype p →₀ β) :
subtype_domain p (map_domain subtype.val f) = f :=
finsupp.ext $ λ a, map_domain_apply _ _ (subtype.val_injective)

--lc ?
def equiv_lc [ring α] [module α β] {s : set β} [decidable_pred s] :
(s →₀ α) ≃ lc.supported s :=
{ to_fun := λ f, ⟨map_domain subtype.val f,
    assume a h,
    have h0 : a ∈ image _ _, from mem_of_subset map_domain_support h,
    let ⟨ap, _, hs⟩ := mem_image.mp h0 in hs ▸ ap.property⟩,
  inv_fun := (finsupp.subtype_domain s) ∘ subtype.val,
  left_inv := subtype_domain_right_inv _,
  right_inv := λ f, subtype.eq $ subtype_domain_left_inv _ f.val f.property }

end finsupp

namespace module

variables {α : Type u} {β : Type v}
variables [ring α] [decidable_eq α]
variables [add_comm_group β] [module α β] [decidable_eq β]
variables {b : set β}

include α β

--basis.lean
noncomputable def equiv_finsupp_basis [decidable_pred b] (h : is_basis b) : β ≃ (b →₀ α) :=
calc β ≃ lc.supported b : (module_equiv_lc h).to_equiv
   ... ≃ (b →₀ α)       : equiv.symm finsupp.equiv_lc

--basis.lean
noncomputable def equiv_fun_basis [decidable_pred b] [fintype b] (h : is_basis b) : β ≃ (b → α) := 
calc β ≃ (b →₀ α) : equiv_finsupp_basis h
   ... ≃ (b → α)  : finsupp.equiv_fun
   
end module

namespace vector_space
 
open fintype module
 
variables (α : Type u) (β : Type v)
variables [discrete_field α] [fintype α]
variables [add_comm_group β] [fintype β]
variables [vector_space α β]

--vector_space
lemma card_fin [deβ : decidable_eq β] : ∃ n : ℕ, card β = (card α) ^ n :=
let ⟨b, hb⟩ := exists_is_basis β in
begin
haveI : fintype b := set.finite.fintype (set.finite.of_fintype b),
haveI : decidable_pred b := set.decidable_mem_of_fintype b,
exact ⟨card b,
  calc card β = card (b → α)    : card_congr (equiv_fun_basis hb)
          ... = card α ^ card b : card_fun⟩
end

end vector_space 
