open Asm

let debug = false 

type t =
	| Nop of (Id.t * Type.t)
	| Set of (Id.t * Type.t) * int
	| SetL of (Id.t * Type.t) * Id.l
	| Float of (Id.t * Type.t) * float
	| Mov of (Id.t * Type.t) * Id.t
	| Neg of (Id.t * Type.t) * Id.t
	| Add of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| Sub of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| Mul of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| Div of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| SLL of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| Ld of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| St of (Id.t * Type.t) * Id.t * Id.t * Asm.id_or_imm
	| FMov of (Id.t * Type.t) * Id.t
	| FNeg of (Id.t * Type.t) * Id.t
	| FAdd of (Id.t * Type.t) * Id.t * Id.t
	| FSub of (Id.t * Type.t) * Id.t * Id.t
	| FMul of (Id.t * Type.t) * Id.t * Id.t
	| FDiv of (Id.t * Type.t) * Id.t * Id.t
	| LdF of (Id.t * Type.t) * Id.t * Asm.id_or_imm
	| StF of (Id.t * Type.t) * Id.t * Id.t * Asm.id_or_imm
	| IfEq of (Id.t * Type.t) * Id.t * Asm.id_or_imm * Id.t * Id.t	(* ラスト２つの引数は基本ブロックのthen節・else節のID *)
	| IfLE of (Id.t * Type.t) * Id.t * Asm.id_or_imm * Id.t * Id.t
	| IfGE of (Id.t * Type.t) * Id.t * Asm.id_or_imm * Id.t * Id.t
	| IfFEq of (Id.t * Type.t) * Id.t * Id.t * Id.t * Id.t
	| IfFLE of (Id.t * Type.t) * Id.t * Id.t * Id.t * Id.t
	| CallCls of (Id.t * Type.t) * Id.t * Id.t list * Id.t list
	| CallDir of (Id.t * Type.t) * Id.l * Id.t list * Id.t list
	| Save of (Id.t * Type.t) * Id.t * Id.t (* レジスタ変数の値をスタック変数へ保存 *)
	| Restore of (Id.t * Type.t) * Id.t (* スタック変数から値を復元 *)

(* 命令 *)
type stmt = {
	mutable sId : Id.t;					(* ID *)
	mutable sParent : Id.t;				(* 所属する基本ブロックのID *)
	mutable sInst : t;						(* 命令内容（Block.t） *)
	mutable sPred : Id.t;			(* 先行命令のID *)
	mutable sSucc : Id.t;			(* 後続命令のID *)
	mutable sLivein : S.t;			(* 入口生存の変数名 *)
	mutable sLiveout : S.t;			(* 出口生存の変数名 *)
}

(* 基本ブロック *)
and block = {
	mutable bId : Id.t;
	mutable bParent : Id.l;				(* 所属する関数のID *)
	mutable bStmts : stmt M.t;				(* ブロックに含まれる命令のID *)
	mutable bHead : Id.t;					(* ブロックの最初の式	 *)
	mutable bTail : Id.t;					(* ブロックの最後の式	 *)
	mutable bPreds : Id.t list;			(* 先行ブロックのID *)
	mutable bSuccs : Id.t list;			(* 後続ブロックのID *)
	mutable bLivein : S.t;			(* 入口生存の変数名 *)
	mutable bLiveout : S.t;			(* 出口生存の変数名 *)
}

(* 関数 *)
and fundef = {
	mutable fName : Id.l;					(* 関数名 *)
	mutable fArgs : Id.t list;				(* 整数引数 *)
	mutable fFargs : Id.t list;				(* 浮動小数引数 *)
	mutable fRet : Type.t;					(* 返り値 *)
	mutable fBlocks : block M.t;			(* 関数に含まれるブロックのID *)
	mutable fHead : Id.t;
	mutable fDef_regs : Id.t list;			(* 関数内で殺される(呼び出す前に退避すべき)レジスタ *)
}


(* プログラム全体 *)
type prog = Prog of fundef list * fundef


(**********************)
(** デバッグ支援関数群 **)
(**********************)

let eprint_list comment ls =
	Printf.eprintf "%s" comment;
	List.iter (Printf.eprintf "%s, ") ls;
	Printf.eprintf "\n"

let print_xt (x, t) = Printf.printf "%s:%s" x (Type.string_of_type t)
let rec print indent f = function
	| Nop xt -> Global.indent indent; print_xt xt; print_endline " = Nop"
	| Set (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = Set %d" x
	| Float (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = Float %f" x
	| SetL (xt, Id.L x) -> Global.indent indent; print_xt xt; Printf.printf " = SetL %s" x
	| Mov (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = Mov %s" x
	| Neg (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = Neg %s" x
	| Add (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = Add %s %s" x (pp_id_or_imm y')
	| Sub (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = Sub %s %s" x (pp_id_or_imm y')
	| Mul (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = Mul %s %s" x (pp_id_or_imm y')
	| Div (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = Div %s %s" x (pp_id_or_imm y')
	| SLL (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = SLL %s %s" x (pp_id_or_imm y')
	| Ld (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = Ld %s %s" x (pp_id_or_imm y')
	| St (xt, x, y, z') -> Global.indent indent; print_xt xt; Printf.printf " = St %s %s %s" x y (pp_id_or_imm z') 
	| FMov (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = FMov %s" x
	| FNeg (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = FNeg %s" x
	| FAdd (xt, x, y) -> Global.indent indent; print_xt xt; Printf.printf " = FAdd %s %s" x y
	| FSub (xt, x, y) -> Global.indent indent; print_xt xt; Printf.printf " = FSub %s %s" x y
	| FMul (xt, x, y) -> Global.indent indent; print_xt xt; Printf.printf " = FMul %s %s" x y
	| FDiv (xt, x, y) -> Global.indent indent; print_xt xt; Printf.printf " = FDiv %s %s" x y
	| LdF (xt, x, y') -> Global.indent indent; print_xt xt; Printf.printf " = LdF %s %s" x (pp_id_or_imm y')
	| StF (xt, x, y, z') -> Global.indent indent; print_xt xt; Printf.printf " = StF %s %s %s" x y (pp_id_or_imm z')
	| IfEq (xt, x, y', b1, b2) -> 
		Global.indent indent; print_xt xt; Printf.printf " = IfEq %s %s %s %s" x (pp_id_or_imm y') b1 b2;
	| IfLE (xt, x, y', b1, b2) -> 
		Global.indent indent; print_xt xt; Printf.printf " = IfLE %s %s %s %s" x (pp_id_or_imm y') b1 b2;
	| IfGE (xt, x, y', b1, b2) -> 
		Global.indent indent; print_xt xt; Printf.printf " = IfGE %s %s %s %s" x (pp_id_or_imm y') b1 b2;
	| IfFEq (xt, x, y, b1, b2) -> 
		Global.indent indent; print_xt xt; Printf.printf " = IfFEq %s %s %s %s" x y b1 b2;
	| IfFLE (xt, x, y, b1, b2) ->
		Global.indent indent; print_xt xt; Printf.printf " = IfFLE %s %s %s %s" x y b1 b2;
	| CallCls (xt, name, args, fargs) -> assert false
	| CallDir (xt, Id.L name, args, fargs) ->
		Global.indent indent; print_xt xt;
		Printf.printf " = CallDir(<%s>, " name;
		List.iter (Printf.printf "%s ") args;
		List.iter (Printf.printf "%s ") fargs;
		print_string ")"
	| Save (xt, x, y) -> Global.indent indent; print_xt xt; Printf.printf " = Save %s %s" x y
	| Restore (xt, x) -> Global.indent indent; print_xt xt; Printf.printf " = Restore %s" x

and print_block indent f {bId = id; bParent = Id.L parent; bStmts = stmts; bHead = head; bTail = tail; bPreds = preds; bSuccs = succs; bLivein = livein; bLiveout = liveout} =
	Global.indent indent; Printf.printf "[%s]\n" id;
	Global.indent indent; Printf.printf "{Parent : %s}\n" parent;
(*	Global.indent indent; Printf.printf "(Head, Tail) = (%s, %s)\n" head tail;
	Global.indent indent; Printf.printf "Pred Blocks= "; List.iter (Printf.printf "%s ") preds; print_newline (); 
	Global.indent indent; Printf.printf "Succ Blocks= "; List.iter (Printf.printf "%s ") succs; print_newline (); 
	Global.indent indent; Printf.printf "Live in = "; S.iter (fun v -> Printf.printf "%s " v) livein; print_newline ();
	Global.indent indent; Printf.printf "Live out = "; S.iter (fun v -> Printf.printf "%s " v) liveout; print_newline ();
*)
	(* print stmts *)
	let rec print_stmts stmt =
(*		Global.indent indent;*)
		print indent f stmt.sInst;
		Printf.printf " : %s\n" stmt.sId;
(*		Global.indent indent; Printf.printf "sPred = %s\n" stmt.sPred; 
		Global.indent indent; Printf.printf "sSucc = %s\n" stmt.sSucc; 
		Global.indent (1 + indent); Printf.printf "sLive in = "; S.iter (fun v -> Printf.printf "%s " v) stmt.sLivein; print_newline (); 
		Global.indent (1 + indent); Printf.printf "sLive out = "; S.iter (fun v -> Printf.printf "%s " v) stmt.sLiveout; print_newline ();*)
		
		if stmt.sSucc <> "" then print_stmts (M.find stmt.sSucc stmts) else () in
	(if M.mem head stmts then print_stmts (M.find head stmts));

	(*	M.iter (fun id stmt -> Printf.printf "%s : " id; print indent f stmt.sInst) stmts;*)
	print_newline ()
	
let print_fundef indent ({fName = Id.L name; fArgs = args; fFargs = fargs; fRet = ret; fBlocks = blocks; fHead = head; fDef_regs = def_regs} as f) = 
	Global.indent indent; Printf.printf "<%s>\n" name;
	Global.indent indent; Printf.printf "Args = "; List.iter (Printf.printf "%s ") args; print_newline (); 
	Global.indent indent; Printf.printf "Fargs = "; List.iter (Printf.printf "%s ") fargs; print_newline (); 
(*	Global.indent indent; Printf.printf "Return type = %s\n" (Type.string_of_type ret);
	Global.indent indent; Printf.printf "def_regs = "; List.iter (Printf.printf "%s ") def_regs; print_newline (); *)
	print_newline ();
	M.iter (fun _ blk -> print_block indent f blk) blocks

let print_prog indent (Prog (fundefs, main_fun)) =
	print_newline ();
	List.iter (print_fundef indent) fundefs;
	print_fundef indent main_fun


(******************************)
(***** 各種データ取得用関数 *****)
(******************************)

let def_sites = ref M.empty
let use_sites = ref M.empty
let def_as_block = ref M.empty
let use_as_block = ref M.empty
let find_assert comment x env = if M.mem x env then M.find x env else (Printf.eprintf "%s NotFound [%s] in FindAssert\n" comment x; assert false)
let get_def_sites x = if M.mem x !def_sites then M.find x !def_sites else []
let get_use_sites x = if M.mem x !use_sites then M.find x !use_sites else []
let get_def_as_block blk_id = find_assert "get_def_as_block" blk_id !def_as_block
let get_use_as_block blk_id = find_assert "get_use_as_block" blk_id !use_as_block

let diff_list ls1 ls2 = Asm.diff_list ls1 ls2

let get_def_use stmt = 
	match stmt.sInst with
		(* 0変数を使用 *)
		| Nop xt
		| Set (xt, _) 
		| SetL (xt, _)
		| Float (xt, _)
		| Restore (xt, _) -> ([fst xt], [])
		(* 1変数を使用 *)
		| Mov (xt, x)
		| Neg (xt, x)
		| Add (xt, x, C _)
		| Sub (xt, x, C _)
		| Mul (xt, x, C _)
		| Div (xt, x, C _)
		| SLL (xt, x, C _)
		| Ld (xt, x, C _)
		| FMov (xt, x)
		| FNeg (xt, x)
		| LdF (xt, x, C _)
		| IfEq (xt, x, C _, _, _)
		| IfLE (xt, x, C _, _, _)
		| IfGE (xt, x, C _, _, _)
		| Save (xt, x, _) -> ([fst xt], [x])
		(* 2変数を使用 *)
		| Add (xt, x, V y)
		| Sub (xt, x, V y)
		| Mul (xt, x, V y)
		| Div (xt, x, V y)
		| SLL (xt, x, V y)
		| Ld (xt, x, V y)
		| St (xt, x, y, C _)
		| FAdd (xt, x, y)
		| FSub (xt, x, y)
		| FMul (xt, x, y)
		| FDiv (xt, x, y)
		| LdF (xt, x, V y)
		| StF (xt, x, y, C _) 
		| IfEq (xt, x, V y, _, _)
		| IfLE (xt, x, V y, _, _)
		| IfGE (xt, x, V y, _, _)
		| IfFEq (xt, x, y, _, _)
		| IfFLE (xt, x, y, _, _) -> ([fst xt], [x; y])
		(* 3変数を使用 *)
		| St (xt, x, y, V z)
		| StF (xt, x, y, V z) -> ([fst xt], [x; y; z])
		(* 変数をいっぱい使用 *)
		| CallCls (xt, name, args, fargs) -> assert false (* クロージャが作られるときはregAlloc.mlでレジスタ割り当てが行われる *)
		| CallDir (xt, Id.L name, args, fargs) -> ([fst xt], args @ fargs)
		
(* 各変数が定義・使用される場所を登録。ついでに各ブロック内で定義・使用される変数群も登録 *)
let set_def_use_sites fundef =
	def_sites := M.empty;
	use_sites := M.empty;
	def_as_block := M.empty;
	use_as_block := M.empty;
	M.iter (
		fun _ blk ->
			let gen = ref S.empty in
			let kill = ref S.empty in
			let rec iter stmt_id =
				let stmt = find_assert "SET_DEF_USE_SITES::iter : " stmt_id blk.bStmts in
				let def, use = get_def_use stmt in
				(* 基本ブロック内のdef(kill), use(gen)の調整。タイガーブックp363参照 *)
				kill := S.union (S.of_list def) !kill;
				gen := S.union (S.of_list use) (S.diff !gen (S.of_list def));
				List.iter (
					fun d ->
						let sites = try M.find d !def_sites with Not_found -> [] in
						def_sites := M.add d ((blk.bId, stmt.sId) :: sites) !def_sites
				) def;
				List.iter (
					fun u ->
						let sites = try M.find u !use_sites with Not_found -> [] in
						use_sites := M.add u ((blk.bId, stmt.sId) :: sites) !use_sites
				) use;
				if stmt.sPred <> "" then iter stmt.sPred in (if not (M.is_empty blk.bStmts) then iter blk.bTail);
			def_as_block := M.add blk.bId !kill !def_as_block;
			use_as_block := M.add blk.bId !gen !use_as_block; 
	) fundef.fBlocks
	


(************************************)
(***** Asm <-> Block 変換系関数群 *****)
(************************************)
let pred_stmt = ref None
let stmt_cnt = ref (-1)
let block_cnt = ref (-1)
let gen_stmt_id  () = stmt_cnt := !stmt_cnt + 1; Printf.sprintf "stmt.%d" !stmt_cnt
let gen_block_id  () = block_cnt := !block_cnt + 1; Printf.sprintf "block.%d" !block_cnt

(* 置換 *)
let replace stmt x y =
	let rep a = if a = x then y else a in
	let rep2 (a, t) = (rep a, t) in
	match stmt.sInst with
		| Nop xt -> Nop (rep2 xt)
		| Set (xt, x) -> Set (rep2 xt, x)
		| SetL (xt, Id.L x) -> SetL (rep2 xt, Id.L x)
		| Float (xt, f) -> Float (rep2 xt, f)
		| Mov (xt, x) -> Mov (rep2 xt, rep x)
		| Neg (xt, x) -> Neg (rep2 xt, rep x)
		| Add (xt, x, V y) -> Add (rep2 xt, rep x, V (rep y))
		| Sub (xt, x, V y) -> Sub (rep2 xt, rep x, V (rep y))
		| Mul (xt, x, V y) -> Mul (rep2 xt, rep x, V (rep y))
		| Div (xt, x, V y) -> Div (rep2 xt, rep x, V (rep y))
		| SLL (xt, x, V y) -> SLL (rep2 xt, rep x, V (rep y))
		| Add (xt, x, C y) -> Add (rep2 xt, rep x, C y)
		| Sub (xt, x, C y) -> Sub (rep2 xt, rep x, C y)
		| Mul (xt, x, C y) -> Mul (rep2 xt, rep x, C y)
		| Div (xt, x, C y) -> Div (rep2 xt, rep x, C y)
		| SLL (xt, x, C y) -> SLL (rep2 xt, rep x, C y)
		| Ld (xt, x, V y) -> Ld (rep2 xt, rep x, V (rep y))
		| St (xt, x, y, V z) -> St (rep2 xt, rep x, rep y, V (rep z))
		| Ld (xt, x, C y) -> Ld (rep2 xt, rep x, C y)
		| St (xt, x, y, C z) -> St (rep2 xt, rep x, rep y, C z)
		| FMov (xt, x) -> FMov (rep2 xt, rep x)
		| FNeg (xt, x) -> FNeg (rep2 xt, rep x)
		| FAdd (xt, x, y) -> FAdd (rep2 xt, rep x, rep y)
		| FSub (xt, x, y) -> FSub (rep2 xt, rep x, rep y)
		| FMul (xt, x, y) -> FMul (rep2 xt, rep x, rep y)
		| FDiv (xt, x, y) -> FDiv (rep2 xt, rep x, rep y)
		| LdF (xt, x, V y) -> LdF (rep2 xt, rep x, V (rep y))
		| StF (xt, x, y, V z) -> StF (rep2 xt, rep x, rep y, V (rep z))
		| LdF (xt, x, C y) -> LdF (rep2 xt, rep x, C y)
		| StF (xt, x, y, C z) -> StF (rep2 xt, rep x, rep y, C z)
		| IfEq (xt, x, V y, b1, b2) -> IfEq (rep2 xt, rep x, V (rep y), b1, b2)
		| IfLE (xt, x, V y, b1, b2) -> IfLE (rep2 xt, rep x, V (rep y), b1, b2)
		| IfGE (xt, x, V y, b1, b2) -> IfGE (rep2 xt, rep x, V (rep y), b1, b2)
		| IfEq (xt, x, C y, b1, b2) -> IfEq (rep2 xt, rep x, C y, b1, b2)
		| IfLE (xt, x, C y, b1, b2) -> IfLE (rep2 xt, rep x, C y, b1, b2)
		| IfGE (xt, x, C y, b1, b2) -> IfGE (rep2 xt, rep x, C y, b1, b2)
		| IfFEq (xt, x, y, b1, b2) -> IfFEq (rep2 xt, rep x, rep y, b1, b2)
		| IfFLE (xt, x, y, b1, b2) -> IfFLE (rep2 xt, rep x, rep y, b1, b2)
		| CallCls (xt, name, args, fargs) -> assert false (* クロージャが作られるときはregAlloc.mlでレジスタ割り当てが行われる *)
		| CallDir (xt, Id.L name, args, fargs) ->
			CallDir (rep2 xt, Id.L name, List.map rep args, List.map rep fargs)
		| Save (xt, x, y) ->
			Save (rep2 xt, rep x, y)
		| Restore (xt, x) ->
			Restore (rep2 xt, x)

(* 文をブロックから除去 *)
let remove_stmt blk stmt =
	assert (M.mem stmt.sId blk.bStmts);
	(if stmt.sPred = "" then (* stmtがブロックの先頭 *)
		blk.bHead <- stmt.sSucc
	else
		let pred = find_assert "Block.remove_stmt1 : " stmt.sPred blk.bStmts in
		pred.sSucc <- stmt.sSucc);
	(if stmt.sSucc = "" then (* stmtがブロックの末尾 *)
		blk.bTail <- stmt.sPred
	else
		let succ = find_assert "Block.remove_stmt2 : " stmt.sSucc blk.bStmts in
		succ.sPred <- stmt.sPred);
	blk.bStmts <- M.remove stmt.sId blk.bStmts

(* 基本ブロックblkの末尾ににinstという命令文を追加 *)
let add_stmt inst blk =
	(* 命令のID作成 *)
	let id = gen_stmt_id () in
	
	let stmt = {
		sId = id;
		sParent = blk.bId;
		sInst = inst;
		sPred = "";
		sSucc = "";
		sLivein = S.empty;
		sLiveout = S.empty
	} in
	(if not (M.is_empty blk.bStmts) then
		match !pred_stmt with
			| None -> assert false
			| Some pred ->
				(pred.sSucc <- stmt.sId;
				stmt.sPred <- pred.sId)
	else (* ブロックの最初の文になるならbHeadに登録 *)
		blk.bHead <- id
	);
	pred_stmt := Some stmt;
	blk.bTail <- id;
	blk.bStmts <- M.add id stmt blk.bStmts

(* 新しく基本ブロックを作成 *)
let make_block blk_id pred succ = {
	bId = blk_id;
	bParent = Id.L "";		(* 所属する関数のID *)
	bStmts = M.empty;		(* ブロックに含まれる命令のID *)
	bHead = "";
	bTail = "";
	bPreds = pred;			(* 先行ブロックのID *)
	bSuccs = succ;			(* 後続ブロックのID *)
	bLivein = S.empty;			(* 入口生存の変数名 *)
	bLiveout = S.empty;			(* 出口生存の変数名 *)
}

(* 基本ブロックblkを関数fに追加 *)
let add_block blk f = 
	List.iter
		(fun blk_id ->
			let pred = find_assert "ADD_BLOCK : " blk_id f.fBlocks in
			pred.bSuccs <- blk.bId :: pred.bSuccs) blk.bPreds;
	blk.bParent <- f.fName;
	f.fBlocks <- M.add blk.bId blk f.fBlocks

let rec g (f : fundef) (blk : block) dest = function
	| Asm.Ans exp ->
		let res_blk = g' f blk dest exp in
		add_block res_blk f;
		res_blk
	| Asm.Let((x, t) as xt, exp, e) ->
		let res_blk = g' f blk xt exp in
		g f res_blk dest e
and g' (f : fundef) (blk : block) xt = function
	| Asm.Nop -> add_stmt (Nop xt) blk; blk
	| Asm.Set x -> add_stmt (Set (xt, x)) blk; blk
	| Asm.SetL x -> add_stmt (SetL (xt, x)) blk; blk
	| Asm.Float x -> assert (snd xt = Type.Float); add_stmt (Float (xt, x)) blk; blk
	| Asm.Mov x -> add_stmt (Mov (xt, x)) blk; blk
	| Asm.Neg x -> add_stmt (Neg (xt, x)) blk; blk
	| Asm.Add (x, y') -> add_stmt (Add (xt, x, y')) blk; blk
	| Asm.Sub (x, y') -> add_stmt (Sub (xt, x, y')) blk; blk
	| Asm.Mul (x, y') -> add_stmt (Mul (xt, x, y')) blk; blk
	| Asm.Div (x, y') -> add_stmt (Div (xt, x, y')) blk; blk
	| Asm.SLL (x, y') -> add_stmt (SLL (xt, x, y')) blk; blk
	| Asm.Ld (x, y') -> add_stmt (Ld  (xt, x, y')) blk; blk
	| Asm.St (x, y, z') -> add_stmt (St (xt, x, y, z')) blk; blk
	| Asm.FMov x -> add_stmt (FMov (xt, x)) blk; blk
	| Asm.FNeg x -> add_stmt (FNeg (xt, x)) blk; blk
	| Asm.FAdd (x, y) -> add_stmt (FAdd (xt, x, y)) blk; blk
	| Asm.FSub (x, y) -> add_stmt (FSub (xt, x, y)) blk; blk
	| Asm.FMul (x, y) -> add_stmt (FMul (xt, x, y)) blk; blk
	| Asm.FDiv (x, y) -> add_stmt (FDiv (xt, x, y)) blk; blk
	| Asm.LdF (x, y') -> add_stmt (LdF (xt, x, y')) blk; blk
	| Asm.StF (x, y, z') -> add_stmt (StF (xt, x, y, z')) blk; blk
	| Asm.IfEq (x, y', e1, e2) ->
		(* ブロックを2つに分岐 *)
		let b1 = gen_block_id () in
		let b2 = gen_block_id () in
		let next_blk_id = gen_block_id () in
		add_stmt (IfEq (xt, x, y', b1, b2)) blk;
		add_block blk f;
		let blk1 = make_block b1 [blk.bId] [] in
		let res_blk1 = g f blk1 xt e1 in
		let blk2 = make_block b2 [blk.bId] [] in
		let res_blk2 = g f blk2 xt e2 in
		let next_blk = make_block next_blk_id [res_blk1.bId; res_blk2.bId] [] in
		next_blk
	| Asm.IfLE (x, y', e1, e2) ->
		(* ブロックを2つに分岐 *)
		let b1 = gen_block_id () in
		let b2 = gen_block_id () in
		let next_blk_id = gen_block_id () in
		add_stmt (IfLE (xt, x, y', b1, b2)) blk;
		add_block blk f;
		let blk1 = make_block b1 [blk.bId] [] in
		let res_blk1 = g f blk1 xt e1 in
		let blk2 = make_block b2 [blk.bId] [] in
		let res_blk2 = g f blk2 xt e2 in
		let next_blk = make_block next_blk_id [res_blk1.bId; res_blk2.bId] [] in
		next_blk
	| Asm.IfGE (x, y', e1, e2) ->
		(* ブロックを2つに分岐 *)
		let b1 = gen_block_id () in
		let b2 = gen_block_id () in
		let next_blk_id = gen_block_id () in
		add_stmt (IfGE (xt, x, y', b1, b2)) blk;
		add_block blk f;
		let blk1 = make_block b1 [blk.bId] [] in
		let res_blk1 = g f blk1 xt e1 in
		let blk2 = make_block b2 [blk.bId] [] in
		let res_blk2 = g f blk2 xt e2 in
		let next_blk = make_block next_blk_id [res_blk1.bId; res_blk2.bId] [] in
		next_blk
	| Asm.IfFEq (x, y, e1, e2) ->
		(* ブロックを2つに分岐 *)
		let b1 = gen_block_id () in
		let b2 = gen_block_id () in
		let next_blk_id = gen_block_id () in
		add_stmt (IfFEq (xt, x, y, b1, b2)) blk;
		add_block blk f;
		let blk1 = make_block b1 [blk.bId] [] in
		let res_blk1 = g f blk1 xt e1 in
		let blk2 = make_block b2 [blk.bId] [] in
		let res_blk2 = g f blk2 xt e2 in
		let next_blk = make_block next_blk_id [res_blk1.bId; res_blk2.bId] [] in
		next_blk
	| Asm.IfFLE (x, y, e1, e2) as exp ->
		(* ブロックを2つに分岐 *)
		let b1 = gen_block_id () in
		let b2 = gen_block_id () in
		let next_blk_id = gen_block_id () in
		add_stmt (IfFLE (xt, x, y, b1, b2)) blk;
		add_block blk f;
		let blk1 = make_block b1 [blk.bId] [] in
		let res_blk1 = g f blk1 xt e1 in
		let blk2 = make_block b2 [blk.bId] [] in
		let res_blk2 = g f blk2 xt e2 in
		let next_blk = make_block next_blk_id [res_blk1.bId; res_blk2.bId] [] in
		next_blk
	| Asm.CallCls _ -> assert false
	| Asm.CallDir (Id.L x, ys, zs) -> add_stmt (CallDir (xt, Id.L x, ys, zs)) blk; blk
	| Asm.Save(x, y) -> add_stmt (Save (xt, x, y)) blk; blk
	| Asm.Restore x -> add_stmt (Restore (xt, x)) blk; blk
	| Asm.Comment _ -> blk

let make_fundef {Asm.name = Id.L x; Asm.args = ys; Asm.fargs = zs; Asm.body = e; Asm.ret = t} = 
	if debug then Printf.eprintf "<%s>\n" x;
	let blk = make_block (gen_block_id ()) [] [] in
	let f = {
		fName = Id.L x;
		fArgs = ys;
		fFargs = zs;
		fRet = t;
		fBlocks = M.empty;
		fHead = blk.bId;
		fDef_regs = []
	} in
	let ret_reg =
		try (M.find x !fundata).ret_reg with Not_found -> "$r0" in
	g f blk (ret_reg, t) e;
	f

let h fundef =
	let name = (fun (Id.L x) -> x) fundef.Asm.name in
	let fundef = make_fundef fundef in
	fundef
	
let f (Asm.Prog(fundefs, e) as prog) = 
	if debug then Printf.eprintf "START make Blocks\n";
(*	Asm.print_prog 0 prog; flush stdout;*)
	let ans = Prog (List.map h fundefs, h {name = Id.L "min_caml_start"; args = []; fargs = []; body = e; ret = Type.Unit}) in
(*	print_prog 0 ans; flush stdout;*)
	if debug then Printf.eprintf "END make Blocks\n";
	ans
	

