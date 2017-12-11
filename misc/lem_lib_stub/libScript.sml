(*Generated by Lem from lib.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory lem_list_extraTheory lem_stringTheory alistTheory llistTheory locationTheory sptreeTheory wordsTheory integer_wordTheory;

val _ = numLib.prefer_num();



val _ = new_theory "lib"

(*
   Extensions to Lem's built-in library to target things we need in HOL.
*)
(*open import Pervasives*)
(*import List_extra*)
(*import String*)

(* TODO: look for these in the built-in library *)

(*val rtc : forall 'a. ('a -> 'a -> bool) -> ('a -> 'a -> bool)*)

(*val disjoint : forall 'a. set 'a -> set 'a -> bool*)

(*val all2 : forall 'a 'b. ('a -> 'b -> bool) -> list 'a -> list 'b -> bool*)

 val _ = Define `
 (the _ (SOME x)=  x) /\ (the x NONE=  x)`;


(*val fapply : forall 'a 'b. MapKeyType 'b => 'a -> 'b -> Map.map 'b 'a -> 'a*)
val _ = Define `
 (fapply d x f=  ((case FLOOKUP f x of SOME d => d | NONE => d )))`;


 val lunion_defn = Defn.Hol_multi_defns `

(lunion [] s=  s)
/\
(lunion (x::xs) s=  
 (if MEM x s
  then lunion xs s
  else x::(lunion xs s)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) lunion_defn;

(* TODO: proper support for nat sets as sptrees... *)
(*open import {hol} `sptreeTheory`*)
(*type nat_set*)
(*val nat_set_empty : nat_set*)
(*val nat_set_is_empty : nat_set -> bool*)
(*val nat_set_insert : nat_set -> nat -> nat_set*)
(*val nat_set_delete : nat_set -> nat -> nat_set*)
(*val nat_set_to_set : nat_set -> set nat*)
(*val nat_set_elem : nat_set -> nat -> bool*)
(*val nat_set_from_list : list nat -> nat_set*)
(*val nat_set_upto : nat -> nat_set*)

(*type nat_map 'a*)
(*val nat_map_empty : forall 'a. nat_map 'a*)
(*val nat_map_domain : forall 'a. nat_map 'a -> set nat*)
(*val nat_map_insert : forall 'a. nat_map 'a -> nat -> 'a -> nat_map 'a*)
(*val nat_map_lookup : forall 'a. nat_map 'a -> nat -> maybe 'a*)
(*val nat_map_to_list : forall 'a. nat_map 'a -> list 'a*)
(*val nat_map_map : forall 'a 'b. ('a -> 'b) -> nat_map 'a -> nat_map 'b*)

(* TODO: proper support for lazy lists *)

(*open import {hol} `llistTheory`*)
(*type llist 'a*)
(*val lhd : forall 'a. llist 'a -> maybe 'a*)
(*val ltl : forall 'a. llist 'a -> maybe (llist 'a)*)
(*val lnil : forall 'a. llist 'a*)
(*val lcons : forall 'a. 'a -> llist 'a -> llist 'a*)


(* TODO: proper support for words... *)
(*open import {hol} `wordsTheory` `integer_wordTheory`*)
(*type word8*)
(*val natFromWord8 : word8 -> nat*)
(*val word_to_hex_string : word8 -> string*)
(*val word8FromNat : nat -> word8*)
(*val word8FromInteger : integer -> word8*)
(*val integerFromWord8 : word8 -> integer*)
(*type word64*)
(*val natFromWord64 : word64 -> nat*)
(*val word64FromNat : nat -> word64*)
(*val word64FromInteger : integer -> word64*)
(*val integerFromWord64 : word64 -> integer*)
(*val word8FromWord64 : word64 -> word8*)
(*val word64FromWord8 : word8 -> word64*)
(*val W8and : word8 -> word8 -> word8*)
(*val W8or : word8 -> word8 -> word8*)
(*val W8xor : word8 -> word8 -> word8*)
(*val W8add : word8 -> word8 -> word8*)
(*val W8sub : word8 -> word8 -> word8*)
(*val W64and : word64 -> word64 -> word64*)
(*val W64or : word64 -> word64 -> word64*)
(*val W64xor : word64 -> word64 -> word64*)
(*val W64add : word64 -> word64 -> word64*)
(*val W64sub : word64 -> word64 -> word64*)

(*val W8lsl : word8 -> nat -> word8*)
(*val W8lsr : word8 -> nat -> word8*)
(*val W8asr : word8 -> nat -> word8*)
(*val W8ror : word8 -> nat -> word8*)
(*val W64lsl : word64 -> nat -> word64*)
(*val W64lsr : word64 -> nat -> word64*)
(*val W64asr : word64 -> nat -> word64*)
(*val W64ror : word64 -> nat -> word64*)

(*open import {hol} `alistTheory`*)
val _ = type_abbrev((* ( 'a, 'b) *) "alist" , ``: ('a # 'b) list``);
(*val alistToFmap : forall 'k 'v. alist 'k 'v -> Map.map 'k 'v*)

(*val opt_bind : forall 'a 'b. maybe 'a -> 'b -> alist 'a 'b -> alist 'a 'b*)
val _ = Define `
 (opt_bind n v e=  
 ((case n of
      NONE => e
    | SOME n' => (n',v)::e
  )))`;


(* Lists of indices *)

 val _ = Define `

(lshift (n : num) ls=  
 (MAP (\ v .  v - n) (FILTER (\ v .  n <= v) ls)))`;


(*open import {hol} `locationTheory`*)
(*type locn = <| row : nat;  col : nat; offset : nat |>*)
(*type locs = (locn * locn)*)
(*val unknown_loc : locs*)
val _ = export_theory()

