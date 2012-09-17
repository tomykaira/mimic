let test x y =
  let abs = 2.0 ** 2. in
  let (c_x, c_y) = (x, y) in
  let rec escapeq z_x z_y iter =
    if z_x ** 2. +. z_y ** 2. >= abs then true
    else if iter == 0 then false
    else escapeq (c_x +. z_x ** 2. -. z_y ** 2.) (c_y +. 2. *. z_x *. z_y) (iter-1)
  in
  escapeq 0.0 0.0 200
;;

let mandelbrot start_x start_y step_x step_y end_x end_y =
  let rec loop_y y =
    let rec loop_x x =
      print_char (if test x y then '0' else '1');
      if x >= end_x then () else loop_x (x +. step_x)
    in
    loop_x start_x;
    print_newline ();
    if y >= end_y then () else loop_y (y +. step_y)
  in
  loop_y start_y
;;

print_char 'P'; print_char '1'; print_newline () ;;
print_int 301; print_char ' '; print_int 201; print_newline () ;; (* XxY*)
print_int 255; print_newline () ;;
mandelbrot (-.2.0) (-.1.0) 0.01 0.01 (1.0) (1.0)
