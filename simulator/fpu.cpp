#include <stdio.h>
#include "fpu.h"

using namespace std;

uint32_t myfadd(uint32_t rs, uint32_t rt)
{
	conv a, b, c;
	a.i = rs;
	b.i = rt;
	c.f = a.f + b.f;
	return c.i;
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
	conv a, b, c;
	a.i = rs;
	b.i = rt;
	c.f = a.f * b.f;
	return c.i;
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
