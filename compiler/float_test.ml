(* gethi, getloはfloat.cで定義された関数。浮動小数をバイナリ列に変換するときに使う *)
external gethi : float -> int32 = "gethi"
external getlo : float -> int32 = "getlo"

let print_two_ints f = 
  let hi = Int32.to_int (gethi f) in
  let lo = Int32.to_int (getlo f) in
  (print_int hi;
   print_string "  "; 
   print_int lo;
   print_newline ())

(* => [16454, 16460, 16467, 16473, 16480, 16486, 16492, 16499, 16505, 16512] *)
(* => [26214, 52429, 13107, 39322, 0, 26214, 52429, 13107, 39322, 0] *)

(* 16454  26214 *)
(* 16460  52429 *)
(* 16467  13107 *)
(* 16473  39322 *)
(* 16480  0 *)
(* 16486  26214 *)

let _ = print_two_ints 3.0
let _ = print_two_ints 3.1
let _ = print_two_ints 3.2
let _ = print_two_ints 3.3
let _ = print_two_ints 3.4
let _ = print_two_ints 3.5
let _ = print_two_ints 3.6
