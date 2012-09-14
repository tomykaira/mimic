	mvhi	$r3, 0
	mvlo	$r3, 4
	mvhi	$r4, 0
	mvlo	$r4, 8
	sti	$r3, $r0, 102
	nop
	nop
	nop
	nop
	ldi	$r5, $r0, 102
	nop
	nop
	nop
	nop
	outputb $r5
	sti	$r4, $r0, 92
	ldi	$r5, $r0, 92
	outputb $r5
	halt
