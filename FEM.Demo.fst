module FEM.Demo

module HS = FStar.HyperStack
module ST = FStar.HyperStack.ST
module B = LowStar.Buffer

open FStar.List
open FStar.Tactics
open FStar.Mul

/// The extended mode requires the FEM.Process module to run meta-processing
/// functions on the code the user is working on. F* needs to know which modules
/// to load from the very start and won't load additional modules on-demand (you
/// will need to restart the F* mode), which means that if you intend to use the
/// extended mode while working on a file, you have to make sure F* will load
/// FEM.Process:
open FEM.Process
/// alternatively if you want to prevent shadowing:
/// module FEMProcess = open FEM.Process

/// Precondition, postcondition, goal, global precondition
/// Unfold, split
/// (goal, global precondition)
/// Stack + normalization
/// Big precondition + split + unfold + split

#push-options "--z3rlimit 100 --fuel 0 --ifuel 0"

/// Some dummy functions used for the below examples
let f1 (n : int) (m : nat) : Pure nat (requires (n > 3)) (ensures (fun _ -> True)) =
  m % (n - 3)

let f2 (x y : nat) :
  Pure (z:nat{z >= 8}) (requires True) (ensures (fun z -> z % 2 = 0)) =
  2 * (x + y) + 8

let f3 (x : nat) : nat =
  2 * x

let f4 (x : nat) : nat =
  x + 8

let f5 (x y : nat) : nat =
  2 * (x + y) + 8

assume val sf1 (r : B.buffer int) :
  ST.Stack int
  (requires (fun _ -> True))
  (ensures (fun h0 n h1 ->
    B.live h0 r /\ B.as_seq h0 r == B.as_seq h1 r /\
    n = List.Tot.fold_left (fun x y -> x + y) 0 (Seq.seq_to_list (B.as_seq h0 r))))

let pred1 (x y z : nat) = True
let pred2 (x y z : nat) = True
let pred3 (x y z : nat) = True
let pred4 (x y z : nat) = True
let pred5 (x y z : nat) = True
let pred6 (x y z : nat) = True

let spred1 (x y z : nat) (h : HS.mem) (r1 r2 r3 : B.buffer int) = True
let spred2 (x y z : nat) (h : HS.mem) (r1 r2 r3 : B.buffer int) = True
let spred3 (x y z : nat) (h : HS.mem) (r1 r2 r3 : B.buffer int) = True
let spred4 (x y z : nat) (h : HS.mem) (r1 r2 r3 : B.buffer int) = True
let invariant1_s (x y z : nat) (h : HS.mem) (r1 r2 r3 : B.buffer int) =
  spred1 x y z h r1 r2 r3 /\
  spred2 x y z h r1 r2 r3 /\
  spred3 x y z h r1 r2 r3 /\
  spred4 x y z h r1 r2 r3    

let invariant1 (x y z : nat) (h : HS.mem) (r1 r2 r3 : B.buffer int) =
  invariant1_s x y z h r1 r2 r3 /\
  B.live h r1 /\ B.live h r2 /\ B.live h r3 /\
  B.disjoint r1 r2 /\ B.disjoint r2 r3 /\ B.disjoint r1 r3

(*** Basic commands *)
(**** Rolling admit *)
/// F* is not always very precise when generating errors to indicate which
/// proof obligation failed to the user. The most common workaround is the
/// "rolling-admit" technique, which consists in inserting an admit in the
/// problematic function and moving it around until we identify the exact
/// piece of code which makes verification fail. This technique is made
/// simpler by the [fem-roll-admit command] (C-x C-a).

/// Try typing C-x C-a anywhere below to insert/move an admit. Note that if
/// insert an admit inside the "if ... then ... else ...", you may have to
/// add a ";" to ensure that F* can parse the function. fem-roll-admit tries
/// to take that into account when you move the admit inside the if.
let sc_ex1 (x : nat) =
  let y = 4 in
  let z = 3 in
  let w : w:nat{w >= 10} =
    if x > 3 then
      begin
      assert(y + x > 7);
      let x' = x + 1 in
      assert(y + x' > 8);
      let x'' = 2 * (y + x') in
      assert(x'' > 16);
      assert(x'' >= 10);
      2 * x'
      end
    else 12
  in
  let w' = 2 * w + z in
  w'

(**** Switch between asserts/assumes *)
/// People often write functions and proofs incrementally, by keeping an admit
/// at the very end and adding function calls or assertions one at a time,
/// type-checking with F* at every changement to make sure that it is legal.
/// However, when such functions or proofs become long, it often takes time
/// to recheck all the already known to succeed proof obligations, before getting
/// to the new (interesting) ones. It is thus useful to be able to quickly switch
/// between assertions and assumptions, to as to ease the proof burden.

/// Try calling fem-switch-assert-assert-in-above-paragraph (C-c C-s C-a) or
/// fem-switch-assert-assert-in-current-line (C-S-a) several times in the below
/// function.
/// Note that the first command operates either on the region above the pointer,
/// or on the active selection.
let sc_ex2 (x : nat) =
  let x1 = x + 1 in
  assert(x1 = x + 1);
  let x2 = 3 * (x1 + 1) in
  assert(x2 = 3 * (x + 2));
  assert(x2 % 3 = 0);
  let x3 = 2 * x2 + 6 in
  assert(x3 = 6 * (x + 2) + 6);
  assert(x3 = 6 * (x + 3));
  assert(x3 % 3 = 0);
  x3

(*** Advanced commands *)
(**** Insert context/proof obligations information *)
/// If often happens that we want to know what exactly the precondition which
/// fails at some specific place is, or if, once instantiated, the postcondition of
/// some lemma is indeed what we believe it is, because it fails to prove some
/// obligation for example, etc. In other words: we sometimes feel blind when
/// working in F*, and the workarounds (mostly copy-pasting and instantiating by hand
/// the relevant pre/postconditions) are often painful.
/// The fem-insert-pre-post command (C-c C-e) addresses this issue.

/// Try testing the fem-insert-pre-post command on the let-bindings and the return result
let ac_ex1 (x y : nat) : z:nat{z % 3 = 0} =
  (* Preconditions:
   * Type C-c C-e below to insert:
   * [> assert(x + 4 > 3); *)
  let x1 = f1 (x + 4) y in (* <- Put your pointer on the left and type C-c C-e *)

  (* Postconditions: *)
  let x2 = f2 x1 y in (* <- Put your pointer on the left and type C-c C-e *)
  (* Type C-c C-e above to insert:
   * [> assert(x2 >= 8);
   * [> assert(x2 % 2 = 0); *)

  (* Typing obligations:
   * Type C-c C-e below to insert:
   * [> assert(Prims.has_type (3 <: Prims.int) Prims.nat); *)
  let x3 = f1 4 3 in (* <- Put your pointer on the left and type C-c C-e *)

  (* Current goal:
   * Type C-c C-e below to insert:
   * [> assert(Prims.has_type (3 * (x1 + x2 + x3) <: Prims.int) Prims.nat);
   * [> assert(3 * (x1 + x2 + x3) % 3 = 0); *)
  3 * (x1 + x2 + x3) (* <- Put your pointer on the left and type C-c C-e *)

/// fem-insert-pre-post also handles the "global" precondition (execute the command
/// while anywhere inside the below function).
let ac_ex2 (x y : int) :
  Pure int
  (requires (x + y >= 0))
  (ensures (fun z -> z >= 0)) =
  (* [> assert(x + y >= 0); *)
  let z = x + y in
  z

/// This command also works on effectful terms. In the case it needs variables it
/// can't find in the context (for example, memory states for the pre/postconditions
/// of some Stack functions), it introduces fresh variables preceded by "__", and
/// abstracts them away, to indicate the user that he needs to provide some variables.
/// It leads to assertions of the form:
/// [> assert((fun __x0 __x1 -> pred __x0 __x1) __x0 __x1)
/// As fem-insert-pre-post performs simple normalization (to remove abstractions,
/// for instance) on the terms it manipulates, the user can rewrite this assert to:
/// [> assert((fun __x0 __x1 -> pred __x0 __x1) x y)
/// then apply C-c C-e on the above assertion to get:
/// [> assert(pred x y)
/// Try this on the stateful calls in the below function. When applying C-c C-e on
/// one of the resulting assertions, make sure you select the WHOLE assertion: as
/// it will likely be written on several lines, the command will need some help for
/// parsing.

let ac_ex3 (r1 r2 : B.buffer int) :
  ST.Stack int (requires (fun _ -> True)) (ensures (fun _ _ _ -> True)) =
  (**) let h0 = ST.get () in
  let n1 = sf1 r1 in (* <- Try C-c C-e here *)
  (* [> assert(
   * [> (fun __h0 __h1 ->
   * [>  LowStar.Monotonic.Buffer.live __h0 r1 /\
   * [>  LowStar.Monotonic.Buffer.as_seq __h0 r1 == LowStar.Monotonic.Buffer.as_seq __h1 r1 /\
   * [>  n1 =
   * [>  FStar.List.Tot.Base.fold_left (fun x y -> x + y)
   * [>    0
   * [>   (FStar.Seq.Properties.seq_to_list (LowStar.Monotonic.Buffer.as_seq __h0 r1))) __h0
   * [> __h1); *)
  (**) let h1 = ST.get () in
  let n2 = sf1 r2 in
  (**) let h2 = ST.get () in
  n1 + n2

(**** Split conjunctions *)
/// Proof obligations are often written in the form of big conjunctions, and
/// figuring out which of those conjuncts fails can be painful, and often requires
/// to copy-paste the proof obligation in an assertion, then split this assertion
/// by hand. The copying part is already taken care of above, and the splitting part
/// can be easily achieved with the fem-split-assert-assume-conjuncts command
/// (C-c C-s C-u):

/// Move the pointer anywhere inside the below assert and use C-c C-s C-u.
/// Note that you don't need to select the assert: the command expects to be inside
/// an assert and can find its boundaries on its own.
let ac_ex4 (x y z : nat) : unit =
  assert( (* <- Try C-c C-s C-u anywhere inside the assert *)
    pred1 x y z /\
    pred2 x y z /\
    pred3 x y z /\
    pred4 x y z /\
    pred5 x y z /\
    pred6 x y z)
  
/// Note that you can call the above command in any of the following terms:
/// - ``assert``
/// - ``assert_norm``
/// - ``assume``

(**** Unfold terms *)
/// It sometimes happens that we need to unfold a term in an assertion, for example
/// in order to check why some equality is not satisfied.
/// fem-unfold-in-assert-assume (C-c C-s C-f) addresses this issue.

let ac_ex5 (x y : nat) : unit =
  let z1 = f3 (x + y) in

  (* Unfold definitions: *)
  assert(z1 = f3 (x + y)); (* <- Move the pointer EXACTLY over ``f3`` and use C-c C-s C-f *)

  (* Unfold arbitrary identifiers:
   * In case the term to unfold is not a top-level definition but a local
   * variable, the command will look for a pure let-binding and will even
   * explore post-conditions to look for an equality to find a term by
   * which to replace the variable. *)
  assert(z1 = 2 * (x + y)); (* <- Try the command on ``z1`` *)

  (* Note that if the assertion is an equality, the command will only
   * operate on one side of the equality at a time. *)
  assert(z1 = z1) // TODO: fix that

/// We intend to update the command to allow arbitrary terms rewriting in the future

(**** Combining commands *)

(**** Two-steps execution *)

/// In the future, we intend to instrument Merlin to parse partially written
/// expressions, so that the user won't have to do two-steps execution to provide
/// parsing information.

(**** Debugging *)
/// You may have bumped into the issue while playing with the above functions:
/// if F* fails on the queries it receives, the interactive commands ask the user
/// if he wants to see the query which was sent, in which case emacs switches
/// between buffers.
/// By doing that, we provide a convenient way for debugging: you may have
/// to modify a bit the functions on which you call the command, or move the
/// pointers before executing it.
/// In the worst case, you can copy paste the query to the current F* buffer, modify
/// it and parse it yourself from there: the results of the analysis by the Meta-F*
/// functions will be output in the *Messages* buffer, from where you can easily
/// copy-paste them, which is still a lot faster than deriving such results by hand.

/// For information: the commands mostly work by inserting appropriate annotations
/// and terms inside the user code, before sending the command to F*. For instance,
/// using C-c C-e in the first function below is equivalent to parsing the second
/// one (modulo the fact that the generated assertions won't be inserted into the
/// user code):

let dbg_ex1 () : Tot nat =
  let x = 4 in
  let y = 2 in
  f1 x y (* <- Use C-c C-e here *)

[@(postprocess_with (pp_analyze_effectful_term false))]
let dbg_ex2 () : Tot nat =
  let x = 4 in
  let y = 2 in
  let _ = focus_on_term in (* helps the post-processing tactic find the term to analyze *)
  f1 x y