	j	fun1

fun1:
	mvhi	$r4, 0
	mvlo	$r4, 8
	call	fun2
	outputb	$r3
	outputb	$r4
	halt

fun2:
	mvhi	$r3, 0
	mvlo	$r3, 4
	return
