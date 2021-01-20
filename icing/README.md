Icing: CAV'19...

[CakeMLtoFloVerLemsScript.sml](CakeMLtoFloVerLemsScript.sml):
Lemmas for connection to FloVer

[CakeMLtoFloVerProofsScript.sml](CakeMLtoFloVerProofsScript.sml):
Central theorem about connection to FloVer

[CakeMLtoFloVerScript.sml](CakeMLtoFloVerScript.sml):
Definition of translation to FloVer

[cfSupportScript.sml](cfSupportScript.sml):
Support lemmas for CF reasoning

[examples](examples):
Case studies for the Marzipan optimizer

[icing_optimisationProofsScript.sml](icing_optimisationProofsScript.sml):
Correctness proofs for Icing optimisations supported by CakeML

[icing_optimisationsLib.sml](icing_optimisationsLib.sml):
Library defining function mk_opt_correct_thms that builds an optimiser
correctness theorem for a list of rewriteFPexp_correct theorems

[icing_optimisationsScript.sml](icing_optimisationsScript.sml):
Icing optimisations supported by CakeML

[icing_rewriterProofsScript.sml](icing_rewriterProofsScript.sml):
Correctness proofs for the expression rewriting function
Shows that matchesExpr e p = SOME s ==> appExpr p s = SOME e

[icing_rewriterScript.sml](icing_rewriterScript.sml):
Implementation of the source to source floating-point rewriter

[source_to_sourceProofsScript.sml](source_to_sourceProofsScript.sml):
Correctness proofs for floating-point optimizations

[source_to_sourceScript.sml](source_to_sourceScript.sml):
Source to source pass, applying Icing optimizations

[supportLib.sml](supportLib.sml):
Library defining commonly used functions for Icing integration