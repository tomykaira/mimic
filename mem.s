	mvhi	$r3, 0
	mvlo	$r3, 4
	sti	$r3, $r0, 102
	outputb $r3
	ldi	$r5, $r0, 102
	outputb $r5
	halt
