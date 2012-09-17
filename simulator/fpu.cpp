#include <stdio.h>
#include "fpu.h"

#define swap(a,b) { int temp = a; a = b; b = temp; }

using namespace std;

uint32_t myfadd(uint32_t rs, uint32_t rt)
{
	unsigned int a = rs;
	unsigned int b = rt;
  unsigned int ae = (a >> 23) & 0xff, be = (b >> 23) & 0xff, diff, sig = 0, msb;
  int se;
  unsigned long long am, bm, sm, sm_orig, x;
  // 0 の扱いはどうにかしたい
  if ((a & 0x7f800000) == 0x7f800000 && a & 0x007fffff) { return a; } // NaN
  if ((b & 0x7f800000) == 0x7f800000 && b & 0x007fffff) { return b; } // NaN
  if (a == 0 && b == 0x80000000) { return 0; }
  if (a == 0 || a == 0x80000000) { return b; }
  if (b == 0 || b == 0x80000000) { return a; }
  if ((a == 0x7f800000 && b == 0xff800000)
      || (b == 0x7f800000 && a == 0xff800000)) { return 0xffc00000; }
  if (be > ae) {
    swap(ae, be);
    swap(a, b);
  }
  // 非正規化数に対処
  if (ae == 0) {
    ae = 1;
    am = (a & 0x7fffff);
  } else {
    am = ((a & 0x7fffff) + 0x800000);
  }

  if (be == 0) {
    be = 1;
    bm = (b & 0x7fffff);
  } else {
    bm = ((b & 0x7fffff) + 0x800000);
  }

  diff = ae - be;
  if (diff > 24) { return a; } // ケタの差がありすぎると計算不能

  se = be;
  sm = (am << diff) * (a >> 31 ? -1 : 1) + bm * (b >> 31 ? -1 : 1);
  if (sm == 0) {
    return 0;
  }

  if ((sm >> 63) == 1) {
    sig = 1;
    sm = - sm;
  }

  sm_orig = sm;

  // overflow??
  msb = 63;
  while ((sm >> msb) == 0) {
    msb --;
  }
  se = be + msb - 23;
  // sm を 23 桁で頭出し
  sm = msb > 23 ? (sm >> (msb - 23)) : (sm << (23 - msb));
  // underflow
  if (se <= 0) {
    return (sig << 31) + (sm >> (1-se));
  }
  if (se >= 255) {
    return (sig << 31) + (0xff << 23);
  }

  x = sm_orig & ((1 << (se - be))-1);
  if (x > (1 << (se - be - 1))
      || (x ==  (1 << (se - be - 1)) && ((sm) & 0x1) == 1)) {
    sm += 1;
  }
  if ((sm >> 23) > 1) {
    sm = sm >> 1;
    se++;
  }

  return (sig << 31) + (se << 23) + (sm & 0x7fffff);
}

uint32_t myfsub(uint32_t rs, uint32_t rt)
{
	conv a, b, c;
	a.i = rs;
	b.i = rt;
	c.f = a.f - b.f;
	return c.i;
}

uint32_t myfmul(uint32_t rs, uint32_t rt)
{
	unsigned int a = rs, b = rt;
  unsigned int ah, al, bh, bl;
  unsigned int hh, hl, lh, m;
  unsigned int ae, be, exp, exp1;
  unsigned int sign, is_zero;
  // stage 1
  ah = ((a >> 11) & 0xfff) + 0x1000;
  bh = ((b >> 11) & 0xfff) + 0x1000;
  al = a & 0x7ff;
  bl = b & 0x7ff;
  hh = ah*bh;
  hl = (ah*bl);
  lh = (al*bh);
  ae = (a >> 23) & 0xff;
  be = (b >> 23) & 0xff;
  exp = ae == 0 || be == 0 ? 0 : ae + be - 127; // -127+2
  sign = (a >> 31) ^ (b >> 31);
  is_zero = (a&0x7fffffff) == 0 || (b&0x7fffffff) == 0;

  // stage 2
  m = hh + (hl >> 11) + (lh >> 11) + 2;
  exp1 = exp + 1;

  // stage 3
  if ((m >> 25) > 0) {
    exp = exp1;
    m = m >> 2;
  } else {
    exp = exp;
    m = m >> 1;
  }

  // inf is disposed to 0
  if ((exp & 0x100) > 0) { exp = 0; m = 0; }
  return (sign << 31) + (is_zero ? 0 : (exp << 23) + (m & 0x7fffff));
}

uint32_t myfdiv(uint32_t rs, uint32_t rt)
{
	conv a, b, c;
	a.i = rs;
	b.i = rt;
	c.f = a.f / b.f;
	return c.i;
}
uint32_t myfinv(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = 1 / a.f;
	return b.i;
}
uint32_t myfsqrt(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = sqrt(a.f);
	return b.i;
}
uint32_t myfabs(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = abs(a.f);
	return b.i;
}
uint32_t myfneg(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = -a.f;
	return b.i;
}
uint32_t myfloor(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = floor(a.f);
	return b.i;
}
uint32_t myfsin(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = sin(a.f);
	return b.i;
}
uint32_t myfcos(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = cos(a.f);
	return b.i;
}
uint32_t myftan(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = tan(a.f);
	return b.i;
}
uint32_t myfatan(uint32_t rs)
{
	conv a, b;
	a.i = rs;
	b.f = atan(a.f);
	return b.i;
}