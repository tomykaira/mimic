	addi	$r3, $r0, 0
	j	callback
callback:
	inputb	$r3
	outputb	$r3
	j	callback
