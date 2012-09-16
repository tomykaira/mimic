#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>

// TODO float用に書き換え

typedef union
{
  int i;
  float f;
} fi;

value gethi(value v)
{
  fi f;
  f.f = (float)Double_val(v);
  return copy_int32(f.i >> 16);
}

value getlo(value v)
{
  fi f;
  f.f = (float)Double_val(v);
  return copy_int32(f.i & 0xffff);
}

