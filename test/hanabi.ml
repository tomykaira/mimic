let pi = 3.141592 in
let center = 150 in
let density = 20 in

let rec rangeEach s e f =
  if s >= e then () else (f s; rangeEach (s + 1) e f)
in

let color r g b =
  let array = Array.create 3 r in
  (array.(1) <- g; 
   array.(2) <- b;
   array)
in
let line() =
  let array = Array.create (center * 2) (color 0 0 0) in
  rangeEach 0 (center * 2) (fun i -> array.(i) <- color 0 0 0);
  array
in
let field =
  let array = Array.create (center * 2) (line()) in
  rangeEach 0 (center * 2) (fun i -> array.(i) <- line());
  array
in

let drawPoint x deg =
  let rad = (2. *. pi *. float_of_int deg /. float_of_int density) in
  let dist = float_of_int x in
  let dx = int_of_float (dist *. cos rad +. dist *. dist *. 0.02) in
  let dy = int_of_float (dist *. sin rad) in
  field.(center + dy).(center + dx) <- color 255 (x * 10) (250-x * 10)
in

let drawCurve deg =
  rangeEach 3 25 (fun dist -> drawPoint dist deg)
in

let print_triple triple =
  print_int triple.(0);
  print_char 32;
  print_int triple.(1);
  print_char 32;
  print_int triple.(2);
  print_char 10; 
in

let _ = (
  print_char 80;
  print_char 51;
  print_newline ();

  print_int (center * 2);
  print_char 32;
  print_int (center * 2);
  print_char 32;
  print_int 255;
  print_newline (); (* XxY*)

  rangeEach 0 density drawCurve; 

  rangeEach 0 (center * 2) (fun x ->
    rangeEach 0 (center * 2) (fun y ->
      print_triple field.(y).(x)
    )
  )
) in 0
