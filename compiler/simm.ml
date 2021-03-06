open Asm

let rec g env = 
  function (* 命令列の13bit即値最適化 (caml2html: simm13_g) *)
  | Ans (Ld(y, V z)) when M.mem y !GlobalEnv.direct_env && not (M.mem z env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
  		Ans (Ld (z, C (- !GlobalEnv.offset + M.find y !GlobalEnv.offsets)))
      )
  | Ans (LdF(y, V z)) when M.mem y !GlobalEnv.direct_env && not (M.mem z env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
  		Ans (LdF (z, C (- !GlobalEnv.offset + M.find y !GlobalEnv.offsets)))
      )
  | Ans (St(y, z, V w)) when M.mem z !GlobalEnv.direct_env && not (M.mem w env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
      		Ans (St (y, w, C (- !GlobalEnv.offset + M.find z !GlobalEnv.offsets)))
      )
  | Ans (StF(y, z, V w)) when M.mem z !GlobalEnv.direct_env && not (M.mem w env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
     		Ans (StF (y, w, C (- !GlobalEnv.offset + M.find z !GlobalEnv.offsets)))
      )
  | Ans(exp) -> Ans(g' env exp)

  | Let((x, t), Set(i), e) when (-4096 <= i) && (i < 4096) ->
      let e' = g (M.add x i env) e in
      if List.mem x (fv e') then Let((x, t), Set(i), e') else
      e'
  | Let(xt, SLL(y, C(i)), e) when M.mem y env -> (* for array access *)
      g env (Let(xt, Set(-((M.find y env) lsl i)), e))

  | Let(xt, Ld(y, V z), e) when M.mem y !GlobalEnv.direct_env && not (M.mem z env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
      	Let (
      		xt,
      		Ld (z, C (- !GlobalEnv.offset + M.find y !GlobalEnv.offsets)),
      		e
      	)
      )
  | Let(xt, St(y, z, V w), e) when M.mem z !GlobalEnv.direct_env && not (M.mem w env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
      	Let (
      		xt,
      		St (y, w, C (- !GlobalEnv.offset + M.find z !GlobalEnv.offsets)),
      		e
      	)
      )
  | Let(xt, LdF(y, V z), e) when M.mem y !GlobalEnv.direct_env && not (M.mem z env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
      	Let (
      		xt,
      		LdF (z, C (- !GlobalEnv.offset + M.find y !GlobalEnv.offsets)),
      		e
      	)
      )
  | Let(xt, StF(y, z, V w), e) when M.mem z !GlobalEnv.direct_env && not (M.mem w env) -> 
      let tmp = Id.gentmp Type.Int in
      g env (
      	Let (
      		xt,
      		StF (y, w, C (- !GlobalEnv.offset + M.find z !GlobalEnv.offsets)),
      		e
      	)
      )
  | Let(xt, exp, e) -> Let(xt, g' env exp, g env e)
and g' env = 
  function (* 各命令の13bit即値最適化 (caml2html: simm13_gprime) *)
  | Add(x, V(y)) when M.mem y env -> Add(x, C(M.find y env))
  | Sub(x, V(y)) when M.mem y env -> Sub(x, C(M.find y env))
  | Mul(x, V(y)) when M.mem y env -> Mul(x, C(M.find y env))
  | Div(x, V(y)) when M.mem y env -> Div(x, C(M.find y env))
  | SLL(x, V(y)) when M.mem y env -> SLL(x, C(M.find y env))

  | Ld(x, V(y)) when M.mem x !GlobalEnv.direct_env && M.mem y env -> Ld(reg_0, C(- !GlobalEnv.offset + M.find x !GlobalEnv.offsets + M.find y env))
  | St(x, y, V(z)) when M.mem y !GlobalEnv.direct_env && M.mem z env -> St(x, reg_0, C(- !GlobalEnv.offset + M.find y !GlobalEnv.offsets + M.find z env))
  | LdF(x, V(y)) when M.mem x !GlobalEnv.direct_env && M.mem y env -> LdF(reg_0, C(- !GlobalEnv.offset + M.find x !GlobalEnv.offsets + M.find y env))
  | StF(x, y, V(z)) when M.mem y !GlobalEnv.direct_env && M.mem z env -> StF(x, reg_0, C(- !GlobalEnv.offset + M.find y !GlobalEnv.offsets + M.find z env))

  | Ld(x, V(y)) when M.mem y env -> Ld(x, C(M.find y env))
  | St(x, y, V(z)) when M.mem z env -> St(x, y, C(M.find z env))
  | LdF(x, V(y)) when M.mem y env -> LdF(x, C(M.find y env))
  | StF(x, y, V(z)) when M.mem z env -> StF(x, y, C(M.find z env))
(*  | IfEq(x, V(y), e1, e2) when M.mem y env -> IfEq(x, C(M.find y env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem y env -> IfLE(x, C(M.find y env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem y env -> IfGE(x, C(M.find y env), g env e1, g env e2)
*)
  | IfEq(x, C(y), e1, e2) -> IfEq(x, C y, g env e1, g env e2)
  | IfLE(x, C(y), e1, e2) -> IfLE(x, C y, g env e1, g env e2)
  | IfGE(x, C(y), e1, e2) -> IfGE(x, C y, g env e1, g env e2)
  | IfEq(x, y', e1, e2) -> IfEq(x, y', g env e1, g env e2)
  | IfLE(x, y', e1, e2) -> IfLE(x, y', g env e1, g env e2)
  | IfGE(x, y', e1, e2) -> IfGE(x, y', g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g env e1, g env e2)
  | e -> e

let h { name = l; args = xs; fargs = ys; body = e; ret = t } = (* トップレベル関数の13bit即値最適化 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) = (* プログラム全体の13bit即値最適化 *)
  let ans = Prog(List.map h fundefs, g M.empty e) in
(*  Asm.print_prog 3 ans;*)
  ans
  

