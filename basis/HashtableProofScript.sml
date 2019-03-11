(*
  Proofs about the Array module.
  load "cfLib";
  load "HashtableProgTheory";
  load "ArrayProofTheory";
*)

open preamble ml_translatorTheory ml_translatorLib cfLib
     mlbasicsProgTheory ArrayProgTheory ArrayProofTheory MapProgTheory HashtableProgTheory
     comparisonTheory;

val _ = new_theory"HashtableProof";

val _ = translation_extends "HashtableProg";

val hashtable_st = get_ml_prog_state();

(*  ----------------------------------- *)

(* the union of each bucket is the heap *)
(* the vlv list contains the buckets *)
(* each bucket only contains keys that hash there *)

val hash_key_set_def = Define`
  hash_key_set hf length idx  = { k' | hf k' MOD length = idx }`;

val bucket_ok_def = Define `
bucket_ok b hf idx length  = !k v.
      (mlmap$lookup b k = SOME v ==> k ∈ (hash_key_set hf length idx))`;

val buckets_empty_def = Define `
  buckets_empty bs = (MAP mlmap$to_fmap bs = (REPLICATE (LENGTH bs) FEMPTY))`;


val buckets_to_fmap_def = Define `
  buckets_to_fmap xs = alist_to_fmap (FLAT (MAP mlmap$toAscList xs))`;



val buckets_ok_def = Define `
   buckets_ok bs hf =
     !i. i < LENGTH bs ==>
       bucket_ok (EL i bs) hf i (LENGTH bs)`;

val hashtable_inv_def = Define `
  hashtable_inv a b hf cmp (h:(('a|->'b) list)) vlv =
    ?buckets.
      h = MAP mlmap$to_fmap buckets /\
      buckets_ok buckets hf /\
      (LENGTH vlv) > 0 /\
      LIST_REL (MAP_TYPE a b) buckets vlv /\
      EVERY mlmap$map_ok buckets`;



val REF_NUM_def = Define `
  REF_NUM loc n =
    SEP_EXISTS v. REF loc v * & (NUM n v)`;

val REF_ARRAY_def = Define `
  REF_ARRAY loc arr content = REF loc arr * ARRAY arr content`;



val HASHTABLE_def = Define
 `HASHTABLE UP a b hf cmp h v =
    SEP_EXISTS ur ar hfv vlv arr cmpv heuristic_size.
      &(v = (Conv (SOME (TypeStamp "Hashtable" 8)) [ur; ar; hfv; cmpv]) /\
        (a --> NUM) hf hfv /\
        (a --> a --> ORDERING_TYPE) cmp cmpv /\
        TotOrd cmp /\
        (hashtable_inv a b hf cmp h vlv) /\
        UP heuristic_size) *
      REF_NUM ur heuristic_size *
      REF_ARRAY ar arr vlv`;

Theorem hashtable_initBuckets_spec
 `!a b n nv cmp cmpv.
    (a --> a --> ORDERING_TYPE) cmp cmpv /\
    NUM n nv ==>
      app (p:'ffi ffi_proj) Hashtable_initBuckets_v [nv; cmpv]
      emp
      (POSTv ar. SEP_EXISTS mpv. &(MAP_TYPE a b (mlmap$empty cmp) mpv) * ARRAY ar (REPLICATE n mpv))`
(xcf_with_def "Hashtable.initBuckets" Hashtable_initBuckets_v_def
\\ xlet `POSTv r1. & (MAP_TYPE a b (mlmap$empty cmp) r1)`
    >-(xapp
    \\ simp[])
\\ xapp_spec array_alloc_spec
\\ xsimpl
\\ asm_exists_tac
\\ simp[]
\\ asm_exists_tac
\\ simp[]);

Theorem buckets_ok_empty
  `!n cmp hf. TotOrd cmp ==>
      buckets_ok (REPLICATE n (mlmap$empty cmp)) hf`
(rpt strip_tac
\\fs[EL_REPLICATE,TotOrder_imp_good_cmp,buckets_ok_def, bucket_ok_def,
  mlmapTheory.empty_thm,balanced_mapTheory.empty_thm,
  mlmapTheory.lookup_thm, balanced_mapTheory.lookup_thm,flookup_thm]);


Theorem hashtable_empty_spec
  `!a b hf hfv cmp cmpv size sizev ar.
      NUM size sizev /\
      (a --> NUM) hf hfv /\
      (a --> a --> ORDERING_TYPE) cmp cmpv /\
      TotOrd cmp ==>
      app (p:'ffi ffi_proj) Hashtable_empty_v [sizev; hfv; cmpv]
        emp
        (POSTv htv. SEP_EXISTS capacity.
            &(size < 1 ==> capacity = 1 /\
              size >= 1 ==> capacity = size) *
           HASHTABLE ($=0) a b hf cmp (REPLICATE capacity FEMPTY) htv)`
(xcf_with_def "Hashtable.empty" Hashtable_empty_v_def
\\xlet_auto
   >-(xsimpl)
THEN1 (xlet `POSTv v. &(NUM 1 v \/ (NUM size' v /\ BOOL F bv))`
  THEN1 (xif
  \\ xlit
  \\ xsimpl
  \\ fs[BOOL_def])
  (*size > 1*)
 THEN1 (xlet `POSTv ar. SEP_EXISTS mpv. &(MAP_TYPE a b (mlmap$empty cmp) mpv) * ARRAY ar (REPLICATE 1 mpv)`
   >-(xapp
  \\ simp[])
THEN1 (xlet `POSTv loc. SEP_EXISTS addr arr. &(addr = loc) * REF_ARRAY loc arr (REPLICATE 1 mpv)`
     >-(xref
      \\ fs[REF_ARRAY_def,REF_NUM_def]
      \\ xsimpl)
THEN1 (xlet `POSTv loc. SEP_EXISTS arr. REF_NUM loc 0 * REF_ARRAY addr arr (REPLICATE 1 mpv)`
     >-(xref
      \\ fs[REF_ARRAY_def, REF_NUM_def]
      \\ xsimpl)
\\ xcon
\\ fs[HASHTABLE_def]
\\ xsimpl
\\ qexists_tac `1`
\\ qexists_tac `(REPLICATE 1 mpv)`
\\ qexists_tac `arr`

\\ xsimpl
\\ fs[hashtable_inv_def]
\\ qexists_tac `(REPLICATE 1 (mlmap$empty cmp))`
\\ rpt conj_tac
THEN1(simp[map_replicate, mlmapTheory.empty_def, balanced_mapTheory.empty_def, mlmapTheory.to_fmap_def])
THEN1(simp[buckets_ok_empty])
THEN1(simp[LIST_REL_REPLICATE_same])
\\fs[EVERY_EL,HD, REPLICATE_GENLIST, GENLIST_CONS, mlmapTheory.empty_thm, balanced_mapTheory.empty_thm])))
(*size > 1*)
THEN1 (xlet `POSTv ar. SEP_EXISTS mpv. &(MAP_TYPE a b (mlmap$empty cmp) mpv) * ARRAY ar (REPLICATE size' mpv)`
   >-(xapp
  \\ simp[])
THEN1 (xlet `POSTv loc. SEP_EXISTS addr arr. &(addr = loc) * REF_ARRAY loc arr (REPLICATE size' mpv)`
     >-(xref
      \\fs[REF_ARRAY_def,REF_NUM_def]
      \\ xsimpl)
THEN1 (xlet `POSTv loc. SEP_EXISTS arr. REF_NUM loc 0 * REF_ARRAY addr arr (REPLICATE size' mpv)`
     >-(xref
    \\ fs[REF_ARRAY_def, REF_NUM_def]
    \\ xsimpl)
\\ xcon
\\ fs[HASHTABLE_def]
\\ xsimpl
\\ qexists_tac `size'`
\\ qexists_tac `(REPLICATE size' mpv)`
\\ qexists_tac `arr`
\\ xsimpl
\\ fs[hashtable_inv_def]
\\ qexists_tac `(REPLICATE size' (mlmap$empty cmp))`
\\ rpt conj_tac
THEN1(simp[map_replicate, mlmapTheory.empty_def, balanced_mapTheory.empty_def, mlmapTheory.to_fmap_def])
THEN1(simp[buckets_ok_empty])
THEN1(fs[BOOL_def])
THEN1(simp[LIST_REL_REPLICATE_same])
\\fs[EVERY_EL,HD, REPLICATE_GENLIST, GENLIST_CONS, mlmapTheory.empty_thm, balanced_mapTheory.empty_thm])))));


Theorem lupdate_fupdate_insert
  `!buckets idx k v.
      EVERY map_ok buckets /\
      idx < LENGTH buckets ==>
      LUPDATE (mlmap$to_fmap (EL idx buckets) |+ (k,v)) idx (MAP mlmap$to_fmap buckets) =
        MAP mlmap$to_fmap (LUPDATE (mlmap$insert (EL idx buckets) k v) idx buckets)`
(fs[EVERY_EL,LIST_REL_EL_EQN,LUPDATE_MAP,mlmapTheory.insert_thm]);


Theorem buckets_ok_insert
  `!buckets hf idx k v.
      EVERY map_ok buckets /\
      buckets_ok buckets hf /\
      idx < LENGTH buckets /\
      idx = hf k MOD LENGTH buckets ==>
        buckets_ok
          (LUPDATE (mlmap$insert (EL idx buckets) k v)
            idx buckets) hf`
(rpt strip_tac
\\fs[EVERY_EL,EL_LUPDATE,buckets_ok_def, bucket_ok_def, hash_key_set_def]
\\strip_tac
\\strip_tac
\\strip_tac
\\strip_tac
\\Cases_on ` i = hf k MOD LENGTH buckets`
\\fs[mlmapTheory.lookup_insert]
\\Cases_on `k=k'`
\\simp[]
\\simp[]
\\simp[]);


Theorem insert_not_empty
  `!a b (mp:('a,'b) map) k v.
      mlmap$map_ok mp ==>
        to_fmap (mlmap$insert mp k v) <> FEMPTY`
(fs[mlmapTheory.insert_thm, mlmapTheory.to_fmap_def,
  balanced_mapTheory.insert_thm,
  balanced_mapTheory.to_fmap_def, FEMPTY_FUPDATE_EQ]);


Theorem list_rel_insert
  `!a b buckets updMap vlv idx k v.
      LIST_REL (MAP_TYPE a b) buckets vlv /\
      MAP_TYPE a b (mlmap$insert (EL idx buckets) k v) updMap /\
      EVERY map_ok buckets /\
      idx < LENGTH buckets  ==>
        LIST_REL (MAP_TYPE a b)
          (LUPDATE (mlmap$insert (EL idx buckets) k v) idx buckets)
        (LUPDATE updMap idx vlv)`
(rpt strip_tac
\\fs[EVERY_EL,LIST_REL_EL_EQN, EL_LUPDATE]
\\strip_tac
\\strip_tac
\\Cases_on `n = idx`
\\fs[mlmapTheory.insert_thm]
\\simp[]);

Theorem every_map_ok_insert
  `!buckets idx k v.
      EVERY map_ok buckets /\
      idx < LENGTH buckets  ==>
        EVERY map_ok (LUPDATE (insert (EL idx buckets) k v) idx buckets)`
(rpt strip_tac
\\fs[EVERY_EL,EL_LUPDATE]
\\strip_tac
\\strip_tac
\\Cases_on `n=idx`
\\fs[mlmapTheory.insert_thm]
\\simp[]);

Theorem hashtable_staticInsert_spec
  `!a b hf hfv cmp cmpv k kv v vv htv used.
      a k kv /\
      b v vv  ==>
      app (p:'ffi ffi_proj) Hashtable_staticInsert_v [htv; kv; vv]
        (HASHTABLE ($= used) a b hf cmp h htv)
        (POSTv uv. SEP_EXISTS hsh fm. &(UNIT_TYPE () uv) *
          HASHTABLE ($=(if fm = FEMPTY then used+1 else used)) a b hf cmp (LUPDATE (fm|+(k,v)) hsh h) htv)`
(xcf_with_def "Hashtable.staticInsert" Hashtable_staticInsert_v_def
\\ fs[HASHTABLE_def]
\\ xpull
\\ xmatch
\\ fs[hashtable_inv_def]
\\ xlet `POSTv arr. SEP_EXISTS aRef arr2 avl uRef uv uvv.
    &(aRef = ar /\ arr2 = arr /\ avl = vlv /\ uRef = ur /\ uv = heuristic_size) *
    REF_ARRAY ar arr vlv * REF ur uvv * & (NUM heuristic_size uvv)`
  >-(xapp
    \\qexists_tac `ARRAY arr vlv * REF_NUM ur heuristic_size`
    \\qexists_tac `arr`
    \\fs[REF_ARRAY_def, REF_NUM_def]
    \\xsimpl)
\\ xlet `POSTv v. SEP_EXISTS length. &(length = LENGTH vlv /\ NUM length v) * REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
  >-(xapp
    \\qexists_tac `aRef ~~> arr2 * REF_NUM uRef uv`
    \\qexists_tac `avl`
    \\fs[REF_ARRAY_def,REF_NUM_def]
    \\xsimpl)
\\ xlet `POSTv v. SEP_EXISTS hashval. &(hashval = (hf k) /\ NUM hashval v) * REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
  >-(xapp
    \\qexists_tac `REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
    \\qexists_tac `k`
    \\qexists_tac `hf`
    \\conj_tac
     >-(qexists_tac `a`
      \\simp[])
    \\xsimpl)
\\ xlet `POSTv v. SEP_EXISTS idx. &(idx = (hashval MOD length') /\ NUM idx v /\
    idx < LENGTH avl /\ idx < LENGTH buckets /\ LENGTH buckets = LENGTH avl) * REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
  >-(xapp
    \\qexists_tac `REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
    \\qexists_tac `&length'`
    \\qexists_tac `&hashval`
    \\fs[NOT_NIL_EQ_LENGTH_NOT_0,X_MOD_Y_EQ_X,LENGTH_NIL_SYM,NUM_def, hashtable_inv_def, LIST_REL_LENGTH]
    \\xsimpl
    \\EVAL_TAC
    \\fs[LIST_REL_LENGTH,NOT_NIL_EQ_LENGTH_NOT_0,LIST_REL_EL_EQN, X_MOD_Y_EQ_X])
\\ xlet `POSTv mp. SEP_EXISTS oldMap. &(oldMap = mp /\ MAP_TYPE a b (EL idx buckets) mp) * REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
 >-(xapp
    \\qexists_tac `aRef ~~> arr2 * REF_NUM uRef uv`
    \\qexists_tac `idx`
    \\qexists_tac `vlv`
    \\fs[hashtable_inv_def,NOT_NIL_EQ_LENGTH_NOT_0,LIST_REL_EL_EQN, X_MOD_Y_EQ_X,REF_ARRAY_def]
    \\xsimpl)
\\ xlet `POSTv retv. SEP_EXISTS newMp.
      &(newMp = retv /\  MAP_TYPE a b (mlmap$insert (EL idx buckets)  k v) retv) * REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
 >-(xapp
    \\qexists_tac `REF_ARRAY aRef arr2 avl * REF_NUM uRef uv`
    \\qexists_tac `v`
    \\qexists_tac `k`
    \\qexists_tac `EL idx buckets`
    \\qexists_tac `b`
    \\qexists_tac `a`
    \\fs[LIST_REL_EL_EQN]
    \\xsimpl)
\\ xlet `POSTv unitv. SEP_EXISTS newBuckets.
    &(UNIT_TYPE () unitv /\ newBuckets = (LUPDATE newMp idx avl)) *
    REF_ARRAY aRef arr2 newBuckets * REF_NUM uRef uv`
  >-(xapp
    \\qexists_tac `aRef ~~> arr2 * REF_NUM uRef uv`
    \\qexists_tac `idx`
    \\qexists_tac `vlv`
    \\fs[REF_ARRAY_def]
    \\xsimpl)
\\ xlet `POSTv b. &(BOOL (mlmap$null (EL idx buckets)) b) * REF_ARRAY aRef arr2 newBuckets * REF_NUM uRef uv`
  >-(xapp
    \\qexists_tac `REF_ARRAY aRef arr2 newBuckets * REF_NUM uRef uv`
    \\qexists_tac `EL idx buckets`
    \\xsimpl
    \\qexists_tac `a`
    \\qexists_tac `b`
    \\fs[])
THEN1 (xif
THEN1 (xlet `POSTv usedv. &(NUM uv usedv) * REF_ARRAY aRef arr2 newBuckets * REF_NUM uRef uv`
  >-(xapp
    \\qexists_tac `REF_ARRAY aRef arr2 newBuckets`
    \\qexists_tac `uvv`
    \\fs[REF_NUM_def, NUM_def, INT_def]
    \\xsimpl)
\\ xlet_auto
  >-(qexists_tac `REF_ARRAY aRef arr2 newBuckets * REF_NUM uRef uv`
    \\xsimpl)
  THEN1( xapp
  \\qexists_tac `REF_ARRAY aRef arr2 newBuckets`
  \\qexists_tac `usedv`
  \\fs[REF_NUM_def, NUM_def, INT_def]
  \\xsimpl
  \\strip_tac
  \\strip_tac
  \\qexists_tac `idx`
  \\qexists_tac `mlmap$to_fmap (EL (hf k MOD LENGTH buckets) buckets)`
  \\qexists_tac `uRef`
  \\qexists_tac `aRef`
  \\qexists_tac `hfv`
  \\qexists_tac `newBuckets`
  \\qexists_tac `arr2`
  \\qexists_tac `cmpv`
  \\qexists_tac `heuristic_size + 1`
  \\xsimpl
  \\qexists_tac `LUPDATE (mlmap$insert (EL (hf k MOD LENGTH buckets) buckets) k v) (hf k MOD LENGTH buckets) buckets`
  \\fs[lupdate_fupdate_insert, buckets_ok_insert, list_rel_insert, every_map_ok_insert]
  \\Cases_on `to_fmap (EL (hf k MOD LENGTH vlv) buckets) = FEMPTY`
  \\simp[]
  \\Cases_on `(EL (hf k MOD LENGTH vlv) buckets)`
  \\Induct_on `b''`
  \\fs[mlmapTheory.null_def,balanced_mapTheory.null_def, balanced_mapTheory.null_thm, mlmapTheory.to_fmap_def]))

  \\xcon
  \\xsimpl
  \\qexists_tac `idx`
  \\qexists_tac `mlmap$to_fmap (EL (hf k MOD LENGTH buckets) buckets)`
  \\qexists_tac `uRef`
  \\qexists_tac `aRef`
  \\qexists_tac `hfv`
  \\qexists_tac `newBuckets`
  \\qexists_tac `arr2`
  \\qexists_tac `cmpv`
  \\qexists_tac `heuristic_size`
  \\xsimpl
  \\qexists_tac `LUPDATE (mlmap$insert (EL (hf k MOD LENGTH buckets) buckets) k v) (hf k MOD LENGTH buckets) buckets`
  \\fs[lupdate_fupdate_insert, buckets_ok_insert, list_rel_insert, every_map_ok_insert]
  \\Cases_on `(EL (hf k MOD LENGTH vlv) buckets)`
  \\simp[]
  \\Induct_on `b''`
  \\fs[mlmapTheory.null_def,balanced_mapTheory.null_def, balanced_mapTheory.null_thm, mlmapTheory.to_fmap_def]
  \\fs[mlmapTheory.null_def,balanced_mapTheory.null_def, balanced_mapTheory.null_thm, mlmapTheory.to_fmap_def]));


val _ = export_theory();
