let rec test x =
  (print_int (int_of_float x);
   if x < 10.0 then test (x +. 1.0) else ())
in
test 0.0
