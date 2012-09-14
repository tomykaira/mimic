	mvhi	$r3, 0
	mvlo	$r3, 4
	mvhi	$r4, 0
	mvlo	$r4, 8
	add	$r5, $r3, $r4
	outputb $r5
	sub	$r5, $r3, $r4
	outputb $r5
	mul	$r5, $r3, $r4
	outputb $r5
	and	$r5, $r3, $r4
	outputb $r5
	or	$r5, $r3, $r4
	outputb $r5
	xor	$r5, $r3, $r4
	outputb $r5
	nor	$r5, $r3, $r4
	outputb $r5
	halt
