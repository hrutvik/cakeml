open HolKernel Parse boolLib bossLib;
open astTheory namespaceTheory semanticPrimitivesTheory typeSystemTheory;
open terminationTheory namespacePropsTheory;

val _ = new_theory "typeSoundInvariants"

(* Type system for values. The invariant that is used for type soundness. *)

val _ = Datatype `
 store_t =
 | Ref_t t
 | W8array_t
 | Varray_t t`;

(* Store typing *)
val _ = type_abbrev( "tenv_store" , ``:(num, store_t) fmap``);

(* Check that the type names map to valid types *)
val tenv_abbrev_ok_def_ = Define `
  tenv_abbrev_ok tenvT ⇔ nsAll (\id (tvs,t). check_freevars 0 tvs t) tenvT`;

val tenv_ctor_ok_def = Define `
  tenv_ctor_ok tenvC ⇔ nsAll (\id (tvs,ts,tn). EVERY (check_freevars 0 tvs) ts) tenvC`;

val tenv_val_ok_def = Define `
  tenv_val_ok tenvV ⇔ nsAll (\id (tvs,t). check_freevars tvs [] t) tenvV`;

val tenv_ok_def = Define `
  tenv_ok tenv ⇔
    tenv_val_ok tenv.v ∧
    tenv_ctor_ok tenv.c ∧
    tenv_abbrev_ok tenv.t`;

val tenv_val_exp_ok_def = Define `
  (tenv_val_exp_ok Empty ⇔ T) ∧
  (tenv_val_exp_ok (Bind_tvar n tenv) ⇔ tenv_val_exp_ok tenv) ∧
  (tenv_val_exp_ok (Bind_name x tvs t tenv) ⇔
    check_freevars (tvs + num_tvs tenv) [] t ∧
    tenv_val_exp_ok tenv)`;

(* Global constructor type environments keyed by constructor name and type
 * stamp. Contains the type variables, the type of the arguments, and
 * the identity of the type. *)
val _ = type_abbrev( "ctMap", ``:((conN # stamp), (tvarN list # t list # (num # num))) fmap``);

val ctMap_ok_def = Define `
  ctMap_ok ctMap ⇔
    (* No free variables in the range *)
    FEVERY (\((cn,stamp),(tvs,ts, _)). EVERY (check_freevars 0 tvs) ts) ctMap ∧
    (* Exceptions have type exception, and no type variables *)
    (!cn ex tvs ts ti. FLOOKUP ctMap (cn, ExnStamp ex) = SOME (tvs, ts, ti) ⇒
      tvs = [] ∧ ti = Texn_num) ∧
    (* Primitive, non-constructor types are not mapped *)
    (!cn x tvs ts ti. FLOOKUP ctMap (cn, TypeStamp x) = SOME (tvs, ts, ti) ⇒
      ~MEM ti [Tarray_num; Tchar_num; Tfn_num; Tint_num; Tref_num; Tstring_num;
               Ttup_num; Tvector_num; Tword64_num; Tword8_num; Tword8array_num]) ∧
    (* Injective as a map from stamps to type identities *)
    (!cn1 stamp1 tvs1 ts1 ti cn2 stamp2 tvs2 ts2.
      FLOOKUP ctMap (cn1,stamp1) = SOME (tvs1, ts1, ti) ∧
      FLOOKUP ctMap (cn2,stamp2) = SOME (tvs2, ts2, ti) ⇒
      stamp1 = stamp2)`;

    (*
val type_decs_to_ctMap_def = Define `
  type_decs_to_ctMap mn tenvT tds ⇔
  FEMPTY |++
  FLAT
    (MAP (\(tvs,tn,ctors).
       MAP (\(cn,ts).
         ((cn,TypeId (mk_id mn tn)), (tvs, MAP (type_name_subst tenvT) ts))) ctors) tds)`;
         *)

(* Check that a constructor type environment is consistent with a runtime type
 * enviroment, using the full type keyed constructor type environment to ensure
 * that the correct types are used. *)
val type_ctor_def = Define `
  type_ctor ctMap _ (n, cn, stamp) (tvs, ts, ti) ⇔
    FLOOKUP ctMap (cn,stamp) = SOME (tvs, ts, ti) ∧
    LENGTH ts = n`;

val add_tenvE_def = Define `
  (add_tenvE Empty tenvV = tenvV) ∧
  (add_tenvE (Bind_tvar _ tenvE) tenvV = add_tenvE tenvE tenvV) ∧
  (add_tenvE (Bind_name x tvs t tenvE) tenvV = nsBind x (tvs,t) (add_tenvE tenvE tenvV))`;

val (type_v_rules, type_v_cases, type_v_ind) = Hol_reln `
  (!tvs ctMap tenvS n.
    type_v tvs ctMap tenvS (Litv (IntLit n)) Tint) ∧
  (!tvs ctMap tenvS c.
    type_v tvs ctMap tenvS (Litv (Char c)) Tchar) ∧
  (!tvs ctMap tenvS s.
    type_v tvs ctMap tenvS (Litv (StrLit s)) Tstring) ∧
  (!tvs ctMap tenvS w.
    type_v tvs ctMap tenvS (Litv (Word8 w)) Tword8) ∧
  (!tvs ctMap tenvS w.
    type_v tvs ctMap tenvS (Litv (Word64 w)) Tword64) ∧
  (!tvs ctMap tenvS cn vs tvs' tn ts' ts ti.
    EVERY (check_freevars tvs []) ts' ∧
    LENGTH tvs' = LENGTH ts' ∧
    LIST_REL (type_v tvs ctMap tenvS)
      vs (MAP (type_subst (FUPDATE_LIST FEMPTY (REVERSE (ZIP (tvs', ts'))))) ts) ∧
    FLOOKUP ctMap (cn, tn) = SOME (tvs',ts,ti)
    ⇒
    type_v tvs ctMap tenvS (Conv (SOME (cn,tn)) vs) (Tapp ts' ti)) ∧
  (!tvs ctMap tenvS vs ts.
    LIST_REL (type_v tvs ctMap tenvS) vs ts
    ⇒
    type_v tvs ctMap tenvS (Conv NONE vs) (Ttup ts)) ∧
  (!tvs ctMap tenvS env tenv tenvE n e t1 t2.
    tenv_ok tenv ∧
    tenv_val_exp_ok tenvE ∧
    num_tvs tenvE = 0 ∧
    nsAll2 (type_ctor ctMap) env.c tenv.c ∧
    nsAll2 (\i v (tvs,t). type_v tvs ctMap tenvS v t) env.v (add_tenvE tenvE tenv.v) ∧
    check_freevars tvs [] t1 ∧
    type_e tenv (Bind_name n 0 t1 (bind_tvar tvs tenvE)) e t2
    ⇒
    type_v tvs ctMap tenvS (Closure env n e) (Tfn t1 t2)) ∧
  (!tvs ctMap tenvS env funs n t tenv tenvE bindings.
    tenv_ok tenv ∧
    tenv_val_exp_ok tenvE ∧
    num_tvs tenvE = 0 ∧
    nsAll2 (type_ctor ctMap) env.c tenv.c ∧
    nsAll2 (\i v (tvs,t). type_v tvs ctMap tenvS v t) env.v (add_tenvE tenvE tenv.v) ∧
    type_funs tenv (bind_var_list 0 bindings (bind_tvar tvs tenvE)) funs bindings ∧
    ALOOKUP bindings n = SOME t ∧
    ALL_DISTINCT (MAP FST funs) ∧
    MEM n (MAP FST funs)
    ⇒
    type_v tvs ctMap tenvS (Recclosure env funs n) t) ∧
  (!tvs ctMap tenvS n t.
    check_freevars 0 [] t ∧
    FLOOKUP tenvS n = SOME (Ref_t t)
    ⇒
    type_v tvs ctMap tenvS (Loc n) (Tref t)) ∧
  (!tvs ctMap tenvS n.
    FLOOKUP tenvS n = SOME W8array_t
    ⇒
    type_v tvs ctMap tenvS (Loc n) Tword8array) ∧
  (!tvs ctMap tenvS n t.
    check_freevars 0 [] t ∧
    FLOOKUP tenvS n = SOME (Varray_t t)
    ⇒
    type_v tvs ctMap tenvS (Loc n) (Tarray t)) ∧
  (!tvs ctMap tenvS vs t.
    check_freevars 0 [] t ∧
    EVERY (\v. type_v tvs ctMap tenvS v t) vs
    ⇒
    type_v tvs ctMap tenvS (Vectorv vs) (Tvector t))`;

val type_sv_def = Define `
  (type_sv ctMap tenvS (Refv v) (Ref_t t) ⇔ type_v 0 ctMap tenvS v t) ∧
  (type_sv ctMap tenvS (W8array v) W8array_t ⇔ T) ∧
  (type_sv ctMap tenvS (Varray vs) (Varray_t t) ⇔
    EVERY (\v. type_v 0 ctMap tenvS v t) vs) ∧
  (type_sv _ _ _ _ ⇔ F)`;


(* The type of the store *)
val type_s_def = Define `
  type_s ctMap envS tenvS ⇔
    (!l.
      ((?st. FLOOKUP tenvS l = SOME st) ⇔ (?v. store_lookup l envS = SOME v)) ∧
      (!st sv.
        FLOOKUP tenvS l = SOME st ∧ store_lookup l envS = SOME sv
        ⇒
        type_sv ctMap tenvS sv st))`;

(* The global constructor type environment has the primitive exceptions in it *)
val ctMap_has_exns_def = Define `
  ctMap_has_exns ctMap ⇔
    FLOOKUP ctMap ("Bind", bind_stamp) = SOME ([],[],Texn_num) ∧
    FLOOKUP ctMap ("Chr", chr_stamp) = SOME ([],[],Texn_num) ∧
    FLOOKUP ctMap ("Div", div_stamp) = SOME ([],[],Texn_num) ∧
    FLOOKUP ctMap ("Subscript", subscript_stamp) = SOME ([],[],Texn_num)`;

(* The global constructor type environment has the list primitives in it *)
val ctMap_has_lists_def = Define `
  ctMap_has_lists ctMap ⇔
    FLOOKUP ctMap ("nil", list_stamp) = SOME (["'a"],[],Tlist_num) ∧
    FLOOKUP ctMap ("::", list_stamp) =
      SOME (["'a"],[Tvar "'a"; Tlist (Tvar "'a")],Tlist_num) ∧
    (!cn. cn ≠ "::" ∧ cn ≠ "nil" ⇒ FLOOKUP ctMap (cn, list_stamp) = NONE)`;

(* The global constructor type environment has the bool primitives in it *)
val ctMap_has_bools_def = Define `
  ctMap_has_bools ctMap ⇔
    FLOOKUP ctMap ("true", bool_stamp) = SOME ([],[],Tbool_num) ∧
    FLOOKUP ctMap ("false", bool_stamp) = SOME ([],[],Tbool_num) ∧
    (!cn. cn ≠ "true" ∧ cn ≠ "false" ⇒ FLOOKUP ctMap (cn, bool_stamp) = NONE)`;

val good_ctMap_def = Define `
  good_ctMap ctMap ⇔
    ctMap_ok ctMap ∧
    ctMap_has_bools ctMap ∧
    ctMap_has_exns ctMap ∧
    ctMap_has_lists ctMap`;

    (*
(* The types and exceptions that are missing are all declared in modules. *)
val weak_decls_only_mods_def = Define `
  weak_decls_only_mods d1 d2 ⇔
    (!tn. Short tn ∈ d1.defined_types ⇒ Short tn ∈ d2.defined_types) ∧
    (!cn. Short cn ∈ d1.defined_exns ⇒ Short cn ∈ d2.defined_exns)`;

(* The run-time declared constructors and exceptions are all either declared in
 * the type system, or from modules that have been declared *)
val consistent_decls_def = Define `
  consistent_decls tes d ⇔
    (!(te :: tes).
       case te of
       | TypeExn cid =>
           cid ∈ d.defined_exns ∨
           (?mn cn. cid = Long mn (Short cn) ∧ [mn] ∈ d.defined_mods)
       | TypeId tid =>
           tid ∈ d.defined_types ∨
           (?mn tn. tid = Long mn (Short tn) ∧([mn] ∈ d.defined_mods)))`;

val consistent_ctMap_def = Define `
  consistent_ctMap d ctMap ⇔
    (!((cn,tid) :: FDOM ctMap).
       case tid of
       | TypeId tn => tn ∈ d.defined_types
       | TypeExn cn => cn ∈ d.defined_exns)`;

val decls_ok_def = Define `
  decls_ok d ⇔ [] ∉ d.defined_mods ∧ decls_to_mods d ⊆ {[]} ∪ d.defined_mods`;
  *)

val type_all_env_def = Define `
  type_all_env ctMap tenvS env tenv ⇔
    nsAll2 (type_ctor ctMap) (sem_env_c env) tenv.c ∧
    nsAll2 (\i v (tvs,t). type_v tvs ctMap tenvS v t) (sem_env_v env) tenv.v`;

val _ = export_theory();
