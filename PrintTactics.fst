module PrintTactics

module HS = FStar.HyperStack
module ST = FStar.HyperStack.ST

open FStar.List
open FStar.Tactics
open FStar.Mul

/// TODO: precondition, postcondition, current goal, unfold

#push-options "--z3rlimit 15 --fuel 0 --ifuel 1"

(* TODO: move to FStar.Tactics.Util.fst *)
#push-options "--ifuel 1"
val iteri_aux: int -> (int -> 'a -> Tac unit) -> list 'a -> Tac unit
let rec iteri_aux i f x = match x with
  | [] -> ()
  | a::tl -> f i a; iteri_aux (i+1) f tl

val iteri: (int -> 'a -> Tac unit) -> list 'a -> Tac unit
let iteri f x = iteri_aux 0 f x
#pop-options


let test_fun1 (n : nat) :
  Pure nat
  (requires (n >= 4))
  (ensures (fun n' -> n' >= 8)) =
  2 * n

let test_fun2 (n : nat) :
  ST.Stack nat
  (requires (fun h1 -> n >= 4))
  (ensures (fun h1 n' h2 -> n' >= 8)) =
  2 * n

let test_fun3 (n : nat) :
  ST.ST nat
  (requires (fun h1 -> n >= 4))
  (ensures (fun h1 n' h2 -> n' >= 8)) =
  2 * n

let test_fun4 (n : nat{n >= 2}) :
  Tot (n':nat{n' >= 8}) =
  4 * n

let test_fun5 (n : nat{n >= 2}) :
  Tot (p:(nat & int){let n1, n2 = p in n1 >= 8 /\ n2 >= 2}) =
  4 * n, 2

let test_fun6 (n1 : nat{n1 >= 4}) (n2 : nat{n2 >= 8}) (n3 : nat{n3 >= 10}) :
  Tot (n:int{n >= 80}) =
  (n1 + n2) * n3

let test_lemma1 (n : nat) :
  Lemma (n * n >= 0) = ()

let test_lemma2 (n : nat) :
  Lemma
  (requires (n >= 4 /\ True))
  (ensures (2 * n >= 8)) = ()

let predicate_with_a_very_long_name_to_ensure_break_line (n : nat) : Type0 =
  n >= 4

let test_lemma3 (n : int{n >= 0}) :
  Lemma
  (requires (
    n >= 4 /\ n * n >= 0 /\ n >= 0 /\ n * n + n + 3 >= 0 /\
    predicate_with_a_very_long_name_to_ensure_break_line n))
  (ensures (2 * n >= 8)) = ()

let test_lemma4 (n1 : nat{n1 >= 3}) (n2 : int{n2 >= 5}) (n3 n4 n5 : nat):
  Lemma
  (requires (n3 + n4 + n5 >= 1))
  (ensures (n1 * n2 * (n3 + n4 + n5) >= 15)) = ()

/// Some constants
let prims_true_name = "Prims.l_True"
let prims_true_term = `Prims.l_True

let pure_effect_name = "Prims.PURE"
let pure_hoare_effect_name = "Prims.Pure"
let stack_effect_name = "FStar.HyperStack.ST.Stack"
let st_effect_name = "FStar.HyperStack.ST.ST"


/// Return the qualifier of a term as a string
val term_construct (t : term) : Tac string

let term_construct (t : term) : Tac string =
  match inspect t with
  | Tv_Var _ -> "Tv_Var"
  | Tv_BVar _ -> "Tv_BVar"
  | Tv_FVar _ -> "Tv_FVar"
  | Tv_App _ _ -> "Tv_App"
  | Tv_Abs _ _ -> "Tv_Abs"
  | Tv_Arrow _ _ -> "Tv_Arrow"
  | Tv_Type _ -> "Tv_Type"
  | Tv_Refine _ _ -> "Tv_Refine"
  | Tv_Const _ -> "Tv_Const"
  | Tv_Uvar _ _ -> "Tv_Uvar"
  | Tv_Let _ _ _ _ _ -> "Tv_Let"
  | Tv_Match _ _ -> "Tv_Match"
  | Tv_AscribedT _ _ _ -> "Tv_AscribedT"
  | Tv_AscribedC _ _ _ -> "Tv_AScribedC"
  | _ -> "Tv_Unknown"

/// Return the qualifier of a comp as a string
val comp_qualifier (c : comp) : Tac string

#push-options "--ifuel 1"
let comp_qualifier (c : comp) : Tac string =
  match inspect_comp c with
  | C_Total _ _ -> "C_Total"
  | C_GTotal _ _ -> "C_GTotal"
  | C_Lemma _ _ _ -> "C_Lemma"
  | C_Eff _ _ _ _ -> "C_Eff"
#pop-options

/// Effect information: we list the current supported effects
type effect_type =
| E_Total | E_GTotal | E_Lemma | E_PURE | E_Pure | E_Stack | E_ST

val effect_type_to_string : effect_type -> string

#push-options "--ifuel 1"
let effect_type_to_string ety =
  match ety with
  | E_Total -> "E_Total"
  | E_GTotal -> "E_GTotal"
  | E_Lemma -> "E_Lemma"
  | E_PURE -> "E_PURE"
  | E_Pure -> "E_Pure"
  | E_Stack -> "E_Stack"
  | E_ST -> "E_ST"
#pop-options

val effect_name_to_type (ename : name) : Tot (option effect_type)

let effect_name_to_type (ename : name) : Tot (option effect_type) =
  let ename = flatten_name ename in
  if ename = pure_effect_name then Some E_PURE
  else if ename = pure_hoare_effect_name then Some E_Pure
  else if ename = stack_effect_name then Some E_Stack
  else if ename = st_effect_name then Some E_ST
  else None

/// Refinement type information
noeq type rtype_info = {
  raw : typ; // Raw type
  refin : term; // Refinement predicate
}

let mk_rtype_info raw refin : rtype_info =
  Mkrtype_info raw refin

/// Type information
noeq type type_info = {
  ty : typ;
  rty : option rtype_info;
}

let mk_type_info ty rty : type_info =
  Mktype_info ty rty

val safe_tc (e:env) (t:term) : Tac (option term)

let safe_tc e t =
  try Some (tc e t) with | _ -> None

val safe_tcc (e:env) (t:term) : Tac (option comp)

let safe_tcc e t =
  try Some (tcc e t) with | _ -> None

val get_rtype_info_from_type : typ -> Tac (option rtype_info)

let get_rtype_info_from_type t =
  match inspect t with
  | Tv_Refine bv refin ->
    let bview : bv_view = inspect_bv bv in
    let raw_type : typ = bview.bv_sort in
    let b : binder = mk_binder bv in
    let refin = pack (Tv_Abs b refin) in
    Some (mk_rtype_info raw_type refin)
  | _ -> None

#push-options "--ifuel 1"
let get_type_info (e:env) (t:term) : Tac (option type_info) =
  match safe_tc e t with
  | None -> None
  | Some ty ->
    let refin = get_rtype_info_from_type ty in
    Some (mk_type_info ty refin)
#pop-options

let get_type_info_from_type (e:env) (ty:term) : Tac type_info =
  let refin = get_rtype_info_from_type ty in
  mk_type_info ty refin

/// Cast information
noeq type cast_info = {
  term : term;
  p_ty : option type_info; // The type of the term
  exp_ty : option type_info; // The type of the expected parameter
}

let mk_cast_info t p_ty exp_ty : cast_info =
  Mkcast_info t p_ty exp_ty

/// Effectful term information
noeq type eterm_info = {
  etype : effect_type;
  pre : option term;
  post : option term;
  ret_type : option type_info;
  (* Head and parameters of the decomposition of the term into a function application *)
  head : term;
  parameters : list cast_info;
  (* The following fields are used when the term is the return value of a
   * function:
   * - ``ret_cast``: contains the cast to the function return type
   * - ``goal``: contains the postcondition of the function *)
  ret_cast : option cast_info;
  goal : option term;
}

let mk_eterm_info etype pre post ret_type head parameters ret_cast goal : eterm_info =
  Mketerm_info etype pre post ret_type head parameters ret_cast goal

(*** Step 1 *)
/// Analyze a term to retrieve its effectful information

/// Decompose a function application between its body and parameters
val decompose_application : env -> term -> Tac (term & list cast_info)

#push-options "--ifuel 1"
let rec decompose_application_aux (e : env) (t : term) :
  Tac (term & list cast_info) =
  match inspect t with
  | Tv_App hd (a, qualif) ->
    let hd0, params = decompose_application_aux e hd in
    (* Parameter type *)
    let a_type = get_type_info e a in
    (* Type expected by the function *)
    let hd_ty = safe_tc e hd in
    let param_type =
      match hd_ty with
      | None -> None
      | Some hd_ty' ->
        match inspect hd_ty' with
        | Tv_Arrow b c ->
          let bv, _ = inspect_binder b in
          let bview = inspect_bv bv in
          let ty = bview.bv_sort in
          let rty = get_rtype_info_from_type ty in
          Some (mk_type_info ty rty)
        | _ -> None
    in
    let cast_info = mk_cast_info a a_type param_type in
    hd0, cast_info :: params
  | _ -> t, []
#pop-options

let decompose_application e t =
  let hd, params = decompose_application_aux e t in
  hd, List.Tot.rev params

/// Returns the effectful information about a term
val get_eterm_info : env -> term -> Tac (option eterm_info)

#push-options "--ifuel 1"
let get_eterm_info (e:env) (t : term) =
  (* Decompose the term if it is a function application *)
  let hd, parameters = decompose_application e t in
  (* Note that the call to ``tcc`` might fail *)
  try
    begin
    let c : comp = tcc e t in
    let cv : comp_view = inspect_comp c in
    match cv with
    | C_Total ret_ty decr ->
      print ("C_Total: " ^ (term_to_string ret_ty));
      let ret_type_info = Some (get_type_info_from_type e ret_ty) in
      Some (mk_eterm_info E_Total None None ret_type_info hd parameters None None)
    | C_GTotal ret_ty decr ->
      print ("C_GTotal: " ^ (term_to_string ret_ty));
      let ret_type_info = Some (get_type_info_from_type e ret_ty) in
      Some (mk_eterm_info E_GTotal None None ret_type_info hd parameters None None)
    | C_Lemma pre post patterns ->
      print "C_Lemma:";
      print ("- pre:\n" ^ (term_to_string pre));
      print ("- post:\n" ^ (term_to_string post));
      print ("- patterns:\n" ^ (term_to_string patterns));
      (* No return type information - we might put unit *)
      Some (mk_eterm_info E_Lemma (Some pre) (Some post) None hd parameters None None)
    | C_Eff univs eff_name ret_ty eff_args ->
      print "C_Eff:";
      print ("- eff_name: " ^ (flatten_name eff_name));
      print ("- result: " ^ (term_to_string ret_ty));
      print "- eff_args:";
      iter (fun (a, _) -> print ("arg: " ^ (term_to_string a))) eff_args;
      let ret_type_info = Some (get_type_info_from_type e ret_ty) in
      (* Handle the common effects *)
      begin match effect_name_to_type eff_name, eff_args with
      | Some E_PURE, [(pre, _)] ->
        Some (mk_eterm_info E_PURE (Some pre) None ret_type_info hd parameters None None)
      | Some E_Pure, [(pre, _); (post, _)] ->
        Some (mk_eterm_info E_Pure (Some pre) (Some post) ret_type_info hd parameters None None)
      | Some E_Stack, [(pre, _); (post, _)] ->
        Some (mk_eterm_info E_Stack (Some pre) (Some post) ret_type_info hd parameters None None)
      | Some E_ST, [(pre, _); (post, _)] ->
        Some (mk_eterm_info E_ST (Some pre) (Some post) ret_type_info hd parameters None None)
      | _, _ ->
        print ("Unknown or inconsistant effect: " ^ (flatten_name eff_name));
        None
      end
    end
  with | _ ->
    print ("get_eterm_info: error: could not compute the type of '" ^
           (term_to_string t) ^ "'");
    None
#pop-options

/// Adds the current goal information to an ``eterm_info`` (if the term is a returned value)
val get_goal_info : eterm_info -> Tac eterm_info

// TODO:
let get_goal_info info =
  let env = cur_env () in
  let goal = cur_goal () in
  info

(*** Step 2 *)
/// The retrieved type refinements and post-conditions are not instantiated (they
/// are lambda functions): instantiate them to get propositions.

val instantiate_type_info_refin : term -> type_info -> Tac type_info

let instantiate_type_info_refin t info =
  match info.rty with
  | Some rinfo ->
    let refin' = mk_e_app rinfo.refin [t] in
    let opt_rinfo' = Some ({rinfo with refin = refin'}) in
    { info with rty = opt_rinfo' }
  | _ -> info

val instantiate_opt_type_info_refin : term -> option type_info -> Tac (option type_info)

let instantiate_opt_type_info_refin t info =
  match info with
  | Some info' -> Some (instantiate_type_info_refin t info')
  | _ -> None

let get_rawest_type (ty:type_info) : Tac typ =
  match ty.rty with
  | Some rty -> rty.raw
  | _ -> ty.ty

let get_rawest_type_from_opt_type_info (ty : option type_info) : Tac (option typ) =
  match ty with
  | Some ty' -> Some (get_rawest_type ty')
  | _ -> None

val instantiate_refinements : env -> eterm_info -> option string -> term ->
  Tac (env & eterm_info)

#push-options "--ifuel 1"
let instantiate_refinements e info ret_arg_name ret_arg =
  (* Create a proper ``ret_arg`` term (in a let binding, the binding variable
   * often gets replaced by the bound expression: we don't want that *)
  let (ret_arg' : term), (e' : env) =
    match get_rawest_type_from_opt_type_info info.ret_type, ret_arg_name with
    | Some ty, Some name ->
      let fbv : bv = fresh_bv_named name ty in
      let b : binder = mk_binder fbv in
      pack (Tv_Var fbv), push_binder e b
    | _ -> ret_arg, e
  in
  (* Instanciate the post-condition and simplify the information *)
  let ipost : option term =
    match info.post with
    | Some post -> Some (mk_e_app post [ret_arg'])
    | None -> None
  in
  (* Retrieve the return type refinement and instanciate it*)
  let iret_type : option type_info =
    match info.ret_type with
    | Some ret_type_info ->
      begin match ret_type_info.rty with
      | Some ret_type_rinfo ->
        let refin' = mk_e_app ret_type_rinfo.refin [ret_arg'] in
        let ret_type_rinfo : rtype_info = { ret_type_rinfo with refin = refin' } in
        let ret_type_info' = { ret_type_info with rty = Some ret_type_rinfo } in
        Some ret_type_info'
      | None -> None
      end
    | _ -> None
  in
  (* Instantiate the refinements in the parameters *)
  let inst_param (p:cast_info) : Tac cast_info =
    let p_ty' = instantiate_opt_type_info_refin p.term p.p_ty in
    let exp_ty' = instantiate_opt_type_info_refin p.term p.exp_ty in
    { p with p_ty = p_ty'; exp_ty = exp_ty' }
  in
  let iparameters = map inst_param info.parameters in
  (* Return *)
  e',
  ({ info with
    post = ipost;
    ret_type = iret_type;
    parameters = iparameters })
#pop-options

(*** Step 3 *)
/// Simplify the information:
/// - simplify the propositions and ignore them if they are trivial (i.e.: True)

/// Check if a proposition is trivial (i.e.: is True)
val is_trivial_proposition : term -> Tac bool

let is_trivial_proposition t =
  term_eq (`Prims.l_True) t

/// Applies normalization steps to an optional proposition (term of type Type).
/// If the proposition gets reduced to True, returns None.
let simplify_opt_proposition (e:env) (steps:list norm_step) (p:option term) :
  Tac (option term) =
  match p with
  | Some x ->
    let x' = norm_term_env e steps x in
    if is_trivial_proposition x' then None else Some x'
  | _ -> None

/// Simplify a type, and remove the refinement if it is trivial
let simplify_type_info (e:env) (steps:list norm_step) (info:type_info) : Tac type_info =
  match info.rty with
  | Some rinfo ->
    let refin' = norm_term_env e steps rinfo.refin in
    if is_trivial_proposition refin' then mk_type_info rinfo.raw None
    else ({ info with rty = Some ({ rinfo with refin = refin' })})
  | _ -> info

let simplify_opt_type_info e steps info : Tac (option type_info) =
  match info with
  | Some info' -> Some (simplify_type_info e steps info')
  | _ -> None

/// Simplify the fields of a term and remove the useless ones (i.e.: trivial conditions)
val simplify_eterm_info : env -> list norm_step -> eterm_info -> Tac eterm_info

#push-options "--ifuel 1"
let simplify_eterm_info e steps info =
  let simpl_prop = simplify_opt_proposition e steps in
  let simpl_type = simplify_opt_type_info e steps in
  let simpl_cast (p:cast_info) : Tac cast_info =
    { p with p_ty = simpl_type p.p_ty; exp_ty = simpl_type p.exp_ty; }
  in
  {
    info with
    pre = simpl_prop info.pre;
    post = simpl_prop info.post;
    ret_type = simpl_type info.ret_type;
    parameters = map simpl_cast info.parameters;
    goal = simpl_prop info.goal;
  }
#pop-options

let has_refinement (ty:type_info) : Tac bool =
  Some? ty.rty

/// Compare the type of a parameter and its expected type
type type_comparison = | Refines | Same_raw_type | Unknown

#push-options "--ifuel 1"
let type_comparison_to_string c =
  match c with
  | Refines -> "Refines"
  | Same_raw_type -> "Same_raw_type"
  | Unknown -> "Unknown"
#pop-options

let compare_types (info1 info2 : type_info) : Tac type_comparison =
  if term_eq info1.ty info2.ty
  then Refines // The types are the same
  else
    let ty1 = get_rawest_type info1 in
    let ty2 = get_rawest_type info2 in
    if term_eq ty1 ty2 then
      if has_refinement info2
      then Same_raw_type // Same raw type but can't say anything about the expected refinement
      else Refines // The first type is more precise than the second type
    else
      Unknown

let compare_param_types (p:cast_info) : Tac type_comparison =
  match p.p_ty, p.exp_ty with
  | Some info1, Some info2 -> compare_types info1 info2
  | _ -> Unknown

(*** Step 4 *)
/// Output the resulting information

let printout_string (prefix data:string) : Tac unit =
  (* Export all at once - actually I'm not sure it is not possible for external
   * output to be mixed here *)
  print (prefix ^ ":\n" ^ data ^ "\n")

let printout_term (prefix:string) (t:term) : Tac unit =
  printout_string prefix (term_to_string t)

let printout_opt_term (prefix:string) (t:option term) : Tac unit =
  match t with
  | Some t' -> printout_term prefix t'
  | None -> printout_string prefix ""

let printout_opt_type (prefix:string) (ty:option type_info) : Tac unit =
  let ty, rty_raw, rty_refin =
    match ty with
    | Some ty' ->
      begin match ty'.rty with
      | Some rty' -> Some ty'.ty, Some rty'.raw, Some rty'.refin
      | _ -> Some ty'.ty, None, None
      end
    | _ -> None, None, None
  in
  printout_opt_term (prefix ^ ":ty") ty;
  printout_opt_term (prefix ^ ":rty_raw") rty_raw;
  printout_opt_term (prefix ^ ":rty_refin") rty_refin

let printout_parameter (prefix:string) (index:int) (p:cast_info) : Tac unit =
  let p_prefix = prefix ^ ":param" ^ string_of_int index in
  printout_term (p_prefix ^ ":term") p.term;
  printout_opt_type (p_prefix ^ ":p_ty") p.p_ty;
  printout_opt_type (p_prefix ^ ":e_ty") p.exp_ty;
  printout_string (p_prefix ^ ":types_comparison")
                  (type_comparison_to_string (compare_param_types p))

let printout_parameters (prefix:string) (parameters:list cast_info) : Tac unit =
  printout_string (prefix ^ ":num") (string_of_int (List.length parameters));
  iteri (printout_parameter prefix) parameters

/// Print the effectful information about a term in a format convenient to
/// use for the emacs commands
val print_eterm_info : env -> eterm_info -> option string -> term -> Tac unit

(* TODO: ret_arg: the introduced variables get replaced... *)
(* TODO: correct naming for variables derived from tuples *)
#push-options "--ifuel 1"
let print_eterm_info e info ret_arg_name ret_arg =
    print ("ret_arg: " ^ term_to_string ret_arg);
    let sinfo = simplify_eterm_info e [primops; simplify] info in
    (* Print the information *)
    print ("eterm_info:BEGIN");
    printout_string "eterm_info:etype" (effect_type_to_string info.etype);
    printout_opt_term "eterm_info:pre" sinfo.pre;
    printout_opt_term "eterm_info:post" sinfo.post;
    printout_opt_type "eterm_info:ret_type" sinfo.ret_type;
    printout_parameters "eterm_info:parameters" sinfo.parameters;
    printout_opt_term "eterm_info:goal" sinfo.goal;
    print ("eterm_info:END")
#pop-options

/// The tactic to be called by the emacs commands
val dprint_eterm : term -> option string -> term -> Tac unit

#push-options "--ifuel 1"
let dprint_eterm t ret_arg_name ret_arg =
  let e = top_env () in
  match get_eterm_info e t with
  | None ->
    (* TODO: fail *)
    print ("dprint_eterm: could not retrieve effect information from: '" ^
           (term_to_string t) ^ "'")
  | Some info ->
    let e = top_env () in
    let e', info' = instantiate_refinements e info ret_arg_name ret_arg in
    print_eterm_info e' info' ret_arg_name ret_arg
#pop-options

let _debug_print_var (name : string) (t : term) : Tac unit =
  print ("_debug_print_var: " ^ name ^ ": " ^ term_to_string t);
  begin match safe_tc (top_env ()) t with
  | Some ty -> print ("type: " ^ term_to_string ty)
  | _ -> ()
  end;
  print ("qualifier: " ^ term_construct t);
  begin match inspect t with
  | Tv_Var bv ->
    let b : bv_view = inspect_bv bv in
    print ("Tv_Var: ppname: " ^ b.bv_ppname ^
           "; index: " ^ (string_of_int b.bv_index) ^
           "; sort: " ^ term_to_string b.bv_sort)
  | _ -> ()
  end;
  print "end of _debug_print_var"

/// We use the following to solve goals requiring a unification variable (for
/// which we might not have a candidate, or for which the candidate may not
/// typecheck correctly). We can't use the tactic ``tadmit`` for the simple
/// reason that it generates a warning which may mess up with the subsequent
/// parsing of the data generated by the tactics.
assume val magic_witness (#a : Type) : a

let tadmit_no_warning () : Tac unit =
  apply (`magic_witness)

let pp_tac () : Tac unit =
  print ("post-processing: " ^ (term_to_string (cur_goal ())));
  dump "";
  trefl()

let test0 () : Lemma(3 >= 2) =
  _ by (
    let s = term_to_string (cur_goal ()) in
    iteri (fun i g -> print ("goal " ^ (string_of_int i) ^ ":" ^
                          "\n- type: " ^ (term_to_string (goal_type g)) ^
                          "\n- witness: " ^ (term_to_string (goal_witness g))))
                          (goals());
    iteri (fun i g -> print ("smt goal " ^ (string_of_int i) ^ ": " ^
                          (term_to_string (goal_type g)))) (smt_goals());
    print ("- qualif: " ^ term_construct (cur_goal ()));
    tadmit_no_warning())

//binders_of_env
//lookup_typ
//lookup_attr
//all_defs_in_env  

#push-options "--ifuel 1"
let print_binder_info (full : bool) (b : binder) : Tac unit =
  let bv, a = inspect_binder b in
  let a_str = match a with
    | Q_Implicit -> "Implicit"
    | Q_Explicit -> "Explicit"
    | Q_Meta t -> "Meta: " ^ term_to_string t
  in
  let bview = inspect_bv bv in
  if full then
    print (
      "> print_binder_info:" ^
      "\n- name: " ^ (name_of_binder b) ^
      "\n- as string: " ^ (binder_to_string b) ^
      "\n- aqual: " ^ a_str ^
      "\n- ppname: " ^ bview.bv_ppname ^
      "\n- index: " ^ string_of_int bview.bv_index ^
      "\n- sort: " ^ term_to_string bview.bv_sort
    )
  else print (binder_to_string b)

let print_binders_info (full : bool) : Tac unit =
  let e = top_env () in
  iter (print_binder_info full) (binders_of_env e)

(*** Alternative: post-processing *)

/// We declare some identifiers that we will use to guide the meta processing
assume type meta_info
assume val focus_on_term : meta_info

exception MetaAnalysis of string
let mfail str =
  raise (MetaAnalysis str)

//type amap 'a 'b = list 'a

/// A map linking variables to terms. For now we use a list to define it, because
/// there shouldn't be too many bindings.
type bind_map = list (bv & term)

let bind_map_push (b:bv) (t:term) (m:bind_map) = (b,t)::m

let rec bind_map_get (b:bv) (m:bind_map) : Tot (option term) =
  match m with
  | [] -> None
  | (b',t)::m' ->
    if compare_bv b b' = Order.Eq then Some t else bind_map_get b m'

let rec bind_map_get_from_name (b:string) (m:bind_map) : Tot (option (bv & term)) =
  match m with
  | [] -> None
  | (b',t)::m' ->
    let b'v = inspect_bv b' in
    if b'v.bv_ppname = b then Some (b',t) else bind_map_get_from_name b m'

noeq type genv =
  {
    env : env;
    bmap : bind_map;
  }
let get_env (e:genv) : env = e.env
let get_bind_map (e:genv) : bind_map = e.bmap
let mk_genv env bmap : genv =
  Mkgenv env bmap

/// Push a binder to a ``genv``. Optionally takes a ``term`` which provides the
/// term the binder is bound to (in a `let _ = _ in` construct for example).
let genv_push_bv (b:bv) (t:option term) (e:genv) : Tac genv =
  match t with
  | Some t' ->
    let br = mk_binder b in
    let e' = push_binder e.env br in
    let bmap' = bind_map_push b t' e.bmap in
    mk_genv e' bmap'
  | None ->
    let br = mk_binder b in
    let e' = push_binder e.env br in
    let bmap' = bind_map_push b (pack (Tv_Var b)) e.bmap in
    mk_genv e' bmap'

let genv_push_binder (b:binder) (t:option term) (e:genv) : Tac genv =
  match t with
  | Some t' ->
    let e' = push_binder e.env b in
    let bmap' = bind_map_push (bv_of_binder b) t' e.bmap in
    mk_genv e' bmap'
  | None ->
    let e' = push_binder e.env b in
    let bv = bv_of_binder b in
    let bmap' = bind_map_push bv (pack (Tv_Var bv)) e.bmap in
    mk_genv e' bmap'

let convert_ctrl_flag (flag : ctrl_flag) =
  match flag with
  | Continue -> Continue
  | Skip -> Continue
  | Abort -> Abort

/// TODO: for now I need to use universe 0 for type a because otherwise it doesn't
/// type check
/// ctrl_flag:
/// - Continue: continue exploring the term
/// - Skip: don't explore the sub-terms of this term
/// - Abort: stop exploration
val explore_term (#a : Type0) (f : a -> genv -> term_view -> Tac (a & ctrl_flag))
                 (x : a) (ge:genv) (t:term) :
  Tac (a & ctrl_flag)

val explore_pattern (#a : Type0) (f : a -> genv -> term_view -> Tac (a & ctrl_flag))
                    (x : a) (ge:genv) (pat:pattern) :
  Tac (genv & a & ctrl_flag)

(* TODO: carry around the list of encompassing terms *)
let rec explore_term #a f x ge t =
  let tv = inspect t in
  let x', flag = f x ge tv in
  if flag = Continue then
    begin match tv with
    | Tv_Var _ | Tv_BVar _ | Tv_FVar _ -> x', Continue
    | Tv_App hd (a,qual) ->
      let x', flag' = explore_term f x ge a in
      if flag' = Continue then
        explore_term f x' ge hd
      else x', convert_ctrl_flag flag'
    | Tv_Abs br body ->
      (* We first explore the type of the binder - the user might want to
       * check information inside the binder definition *)
      let bv = bv_of_binder br in
      let bvv = inspect_bv bv in
      let x', flag' = explore_term f x ge bvv.bv_sort in
      if flag' = Continue then
        let ge' = genv_push_binder br None ge in
        explore_term f x' ge' body
      else x', convert_ctrl_flag flag'
    | Tv_Arrow br c -> x, Continue (* TODO: we might want to explore that *)
    | Tv_Type () -> x, Continue
    | Tv_Refine bv ref ->
      let bvv = inspect_bv bv in
      let x', flag' = explore_term f x ge bvv.bv_sort in
      if flag' = Continue then
        let ge' = genv_push_bv bv None ge in
        explore_term f x' ge' ref
      else x', convert_ctrl_flag flag'
    | Tv_Const _ -> x, Continue
    | Tv_Uvar _ _ -> x, Continue
    | Tv_Let recf attrs bv def body ->
      (* We need to check if the let definition is a meta identifier *)
//      if term_eq def (`focus_on_term) then
//        begin
//        (* TODO: process *)
//        print ("[> Focus on term: " ^ term_to_string body);
//        x
//        end
//      else
      let bvv = inspect_bv bv in
      let x', flag' = explore_term f x ge bvv.bv_sort in
      if flag' = Continue then
        let x'', flag'' = explore_term f x' ge body in
        if flag'' = Continue then
          let ge' = genv_push_bv bv (Some def) ge in
          explore_term f x ge' body
        else x'', convert_ctrl_flag flag''
      else x', convert_ctrl_flag flag'
    | Tv_Match scrutinee branches ->
      let explore_branch (x_flag : a & ctrl_flag) (br : branch) : Tac (a & ctrl_flag)=
        let x, flag = x_flag in
        if flag = Continue then
          let pat, t = br in
          let ge', x', flag' = explore_pattern #a f x ge pat in
          if flag' = Continue then
            explore_term #a f x' ge' t
          else x', convert_ctrl_flag flag'
        (* Don't convert the flag *)
        else x, flag
      in
      let x' = explore_term #a f x ge scrutinee in
      fold_left explore_branch x' branches
    | Tv_AscribedT e ty tac ->
      let x', flag = explore_term #a f x ge e in
      if flag = Continue then
        explore_term #a f x' ge ty
      else x', convert_ctrl_flag flag
    | Tv_AscribedC e c tac ->
      (* TODO: explore the comp *)
      explore_term #a f x ge e
    | _ ->
      (* Unknown *)
      x, Continue
    end
  else x', convert_ctrl_flag flag

and explore_pattern #a f x ge pat =
  match pat with
  | Pat_Constant _ -> ge, x, Continue
  | Pat_Cons fv patterns ->
    let explore_pat ge_x_flag pat =
      let ge, x, flag = ge_x_flag in
      let pat', _ = pat in
      if flag = Continue then
        explore_pattern #a f x ge pat'
      else
        (* Don't convert the flag *)
        ge, x, flag
    in
    fold_left explore_pat (ge, x, Continue) patterns
  | Pat_Var bv | Pat_Wild bv ->
    let ge' = genv_push_bv bv None ge in
    ge', x, Continue
  | Pat_Dot_Term bv t ->
    (* TODO: I'm not sure what this is *)
    let ge' = genv_push_bv bv None ge in
    ge', x, Continue

let print_dbg (debug : bool) (s : string) : Tac unit =
  if debug then print s

let pp_explore (#a : Type0) (f : a -> genv -> term_view -> Tac (a & ctrl_flag))
               (x : a) :
  Tac unit =
  print "[> start_explore_term";
  let g = cur_goal () in
  let e = cur_env () in
  begin match term_as_formula g with
  | Comp (Eq _) l r ->
    let ge = mk_genv e [] in
    let x = explore_term #a f x ge l in
    trefl()
  | _ -> mfail "pp_explore: not a squashed equality"
  end

/// Effectful term analysis: analyze a term in order to print propertly instantiated
/// pre/postconditions and type conditions.
val analyze_effectful_term : unit -> genv -> term_view -> Tac (unit & ctrl_flag)

let analyze_effectful_term () ge t =
  match t with
  | Tv_Let recf attrs bv def body ->
    (* We need to check if the let definition is a meta identifier *)
     if term_eq def (`focus_on_term) then
       begin
       print ("[> Focus on term: " ^ term_to_string body);
       (), Abort
       end
     else (), Continue
  | _ -> (), Continue

val pp_focused_term : unit -> Tac unit
let pp_focused_term () =
  pp_explore analyze_effectful_term ()

(*** Tests *)
(**** Post-processing *)

[@(postprocess_with pp_focused_term)]
let pp_test1 () : Tot nat =
  let x = 1 in
  let y = 2 in
  if x >= y then
    let _ = focus_on_term in
    test_fun1 (3 * x + y)
  else 0
  

(**** Wrapping with tactics *)

// Rk.: problems with naming: use synth: let x = _ by (...)
  
#push-options "--admit_smt_queries true"
[@(postprocess_with pp_tac)]
let test1 (x : nat{x >= 4}) (y : int{y >= 10}) (z : nat{z >= 12}) :
  Pure (n:nat{n >= 17})
  (requires (x % 3 = 0))
  (ensures (fun n -> n % 2 = 0)) =
  test_lemma1 x; (**)
  run_tactic (fun _ -> print_binders_info true);
  17

let test2 (x : nat{x >= 4}) (y : int{y >= 10}) (z : nat{z >= 12}) :
  Lemma(x + y + z >= 26) =
  (* Look for the binder after the one with type "Prims.pure_post".
   * Or: count how many parameters the function has... *)
  run_tactic (fun _ -> print_binders_info true)

let test3 (x : nat{x >= 4}) (y : int{y >= 10}) (z : nat{z >= 12}) :
  Lemma (requires x % 2 = 0) (ensures x + y + z >= 26) =
  (* The pre and the post are put together in a conjunction *)
  run_tactic (fun _ -> print_binders_info true)

let test4 (x : nat{x >= 4}) :
  ST.Stack nat
  (requires (fun h -> x % 2 = 0))
  (ensures (fun h1 y h2 -> y % 3 = 0)) =
  (* Look after FStar.Pervasives.st_post_h FStar.Monotonic.HyperStack.mem Prims.nat
   * and FStar.Monotonic.HyperStack.mem *)
  run_tactic (fun _ -> print_binders_info true);
  3

let test5 (x : nat{x >= 4}) :
  ST.Stack nat
  (requires (fun h -> x % 2 = 0))
  (ensures (fun h1 y h2 -> y % 3 = 0)) =
  (* Shadowing: we can't use the pre anymore... *)
  let x = 5 in
  test_lemma1 x;
  run_tactic (fun _ -> print_binders_info false);
  3

let test5_1 (x : nat{x >= 4}) :
  ST.Stack nat
  (requires (fun h -> x % 2 = 0))
  (ensures (fun h1 y h2 -> y % 3 = 0)) =
  (* When using ``synth``, we don't see the same thing *)
  let x = 5 in
  test_lemma1 x;
  let _ : unit = _ by (print_binders_info false; exact (`())) in
  3

(* Playing with module definitions *)
let test5_2 (x : nat{x >= 4}) :
  ST.Stack nat
  (requires (fun h -> x % 2 = 0))
  (ensures (fun h1 y h2 -> y % 3 = 0)) =
  let x = 5 in
  test_lemma1 x;
  run_tactic (
    fun () ->
    let opt_sig = lookup_typ (top_env ()) ["PrintTactics"; "Unknown"] in
    begin match opt_sig with
    | Some sig -> print "Found signature"
    | _ -> print "No signature"
    end;
    iter (fun fv -> print (fv_to_string fv)) (defs_in_module (top_env()) ["PrintTactics"])
    );
  3

(* Trying to use different names between the declaration and the definition *)
val test6 (x : nat{x >= 4}) :
  ST.Stack nat
  (requires (fun h -> x % 2 = 0))
  (ensures (fun h1 y h2 -> y % 3 = 0))

(* It's ok: the pre references y *)
let test6 y =
  run_tactic (fun _ -> print_binders_info false);
  3

(* TODO: what is ``lookup_attr`` used for? *)
let test7 (x : nat) : nat =
  [@inline_let] let y = x + 1 in
  run_tactic (fun _ ->
    let e = top_env () in
    print "> lookup_attr";
    iter (fun a -> print (flatten_name (inspect_fv a))) (lookup_attr (quote y) e);
    (* Warning: takes some time! *)
//    print "> all_defs_in_env";
//    iter (fun a -> print (flatten_name (inspect_fv a))) (all_defs_in_env e);
    ()
  );
  0

//binders_of_env
//lookup_typ
//lookup_attr
//all_defs_in_env  


//[@(postprocess_with pp_tac)]
let test8 (x : nat{x >= 4}) (y : int{y >= 10}) (z : nat{z >= 12}) :
  Tot (n:nat{n % 2 = 0}) =
//  run_tactic (fun _ -> print (term_to_string (quote ((**) x))));
  let a = 3 in
//  FStar.Tactics.Derived.run_tactic (fun _ -> PrintTactics.dprint_eterm (quote (test_lemma1 x)) None (`()) [(`())]);
  (**) test_lemma1 x; (**)
  test_lemma1 (let y = x in y); (**)
  let w = 3 in
  test_lemma1 w;
  test_lemma3 x;
  (**) test_lemma3 x; (**)
  (**) test_lemma3 y; (**)
  test_lemma4 x y x 1 2;
  let w = test_fun4 x in
  _ by (
    let s = term_to_string (cur_goal ()) in
    iteri (fun i g -> print ("goal " ^ (string_of_int i) ^ ": " ^
                          (term_to_string (goal_type g)))) (goals());
    iteri (fun i g -> print ("smt goal " ^ (string_of_int i) ^ ": " ^
                          (term_to_string (goal_type g)))) (smt_goals());
    tadmit_no_warning())

//  run_tactic (fun _ -> dprint_eterm (quote (test_fun4 x)) (Some "w") (quote w) [(`())]);
//  run_tactic (fun _ -> dprint_eterm (quote (test_fun6 x (2 * x) (3 * x))) (Some "a") (quote y) [(`())]);
//  run_tactic (fun _ -> dprint_eterm (quote (test_fun6 x y z)) (Some "a") (quote y) [(`())]);

(*
   (setq debug-on-error t)

  let n1, n2 = test_fun5 x in
//  run_tactic (fun _ -> print ("n1: " ^ term_to_string (quote n1)));
  run_tactic (fun _ -> _debug_print_var "n1" (quote n1));
  run_tactic (fun _ -> _debug_print_var "n2" (quote n2));
  run_tactic (fun _ -> dprint_eterm (quote (test_fun5 x)) None (`(`#(quote n1), `#(quote n2))) [(`())]);
  x


let test2 (x : nat{x >= 4}) : nat =
  test_lemma1 x; (**)
  (**) test_lemma1 x; (**)
  test_lemma1 (let y = x in y); (**)
  test_lemma2 x;
  test_lemma2 6;
  let y = 3 in
  test_lemma1 y;
  test_lemma3 x;
  admit()

  x = 3;
