	j	min_caml_start

#----------------------------------------------------------------------
#
# lib_asm.s
#
#----------------------------------------------------------------------

# * create_array
min_caml_create_array:
	add $r5, $r3, $r2
	mov $r3, $r2
CREATE_ARRAY_LOOP:
	blt  $r2, $r5, CREATE_ARRAY_CONTINUE
	return
CREATE_ARRAY_CONTINUE:
	sti $r4, $r2, 0	
	addi $r2, $r2, 1	
	j CREATE_ARRAY_LOOP

# * create_float_array
min_caml_create_float_array:
	add $r4, $r3, $r2
	mov $r3, $r2
CREATE_FLOAT_ARRAY_LOOP:
	blt $r2, $r4, CREATE_FLOAT_ARRAY_CONTINUE
	return
CREATE_FLOAT_ARRAY_CONTINUE:
	fsti $f0, $r2, 0
	addi $r2, $r2, 1
	j CREATE_FLOAT_ARRAY_LOOP

# * floor		$f0 + MAGICF - MAGICF
min_caml_floor:
	fmov $f1, $f0
	# $f4 <- 0.0
	# fset $f4, 0.0
	fmvhi $f4, 0
	fmvlo $f4, 0
	fblt $f0, $f4, FLOOR_NEGATIVE	# if ($f4 <= $f0) goto FLOOR_PISITIVE
FLOOR_POSITIVE:
	# $f2 <- 8388608.0(0x4b000000)
	fmvhi $f2, 19200
	fmvlo $f2, 0
	fblt $f2, $f0, FLOOR_POSITIVE_RET
FLOOR_POSITIVE_MAIN:
	fmov $f1, $f0
	fadd $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r4, $r1, 0
	fsub $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r4, $r1, 0
	fblt $f1, $f0, FLOOR_POSITIVE_RET
	return
FLOOR_POSITIVE_RET:
	# $f3 <- 1.0
	# fset $f3, 1.0
	fmvhi $f3, 16256
	fmvlo $f3, 0
	fsub $f0, $f0, $f3
	return
FLOOR_NEGATIVE:
	fneg $f0, $f0
	# $f2 <- 8388608.0(0x4b000000)
	fmvhi $f2, 19200
	fmvlo $f2, 0
	fblt $f2, $f0, FLOOR_NEGATIVE_RET
FLOOR_NEGATIVE_MAIN:
	fadd $f0, $f0, $f2
	fsub $f0, $f0, $f2
	fneg $f1, $f1
	fblt $f0, $f1, FLOOR_NEGATIVE_PRE_RET
	j FLOOR_NEGATIVE_RET
FLOOR_NEGATIVE_PRE_RET:
	fadd $f0, $f0, $f2
	# $f3 <- 1.0
	# fset $f3, 1.0
	fmvhi $f3, 16256
	fmvlo $f3, 0
	fadd $f0, $f0, $f3
	fsub $f0, $f0, $f2
FLOOR_NEGATIVE_RET:
	fneg $f0, $f0
	return
	
min_caml_ceil:
	fneg $f0, $f0
	call min_caml_floor
	fneg $f0, $f0
	return

# * float_of_int
min_caml_float_of_int:
	blt $r3, $r0, ITOF_NEGATIVE_MAIN		# if ($r0 <= $r3) goto ITOF_MAIN
ITOF_MAIN:
	# $f1 <- 8388608.0(0x4b000000)
	fmvhi $f1, 19200
	fmvlo $f1, 0
	# $r4 <- 0x4b000000
	mvhi $r4, 19200
	mvlo $r4, 0
	# $r5 <- 0x00800000
	mvhi $r5, 128
	mvlo $r5, 0
	blt $r3, $r5, ITOF_SMALL
ITOF_BIG:
	# $f2 <- 0.0
	# fset $f2, 0.0
	fmvhi $f2, 0
	fmvlo $f2, 0
ITOF_LOOP:
	sub $r3, $r3, $r5
	fadd $f2, $f2, $f1
	blt $r3, $r5, ITOF_RET
	j ITOF_LOOP
ITOF_RET:
	add $r3, $r3, $r4
	sti $r3, $r1, 0
	fldi $f0, $r1, 0
	fsub $f0, $f0, $f1
	fadd $f0, $f0, $f2
	return
ITOF_SMALL:
	add $r3, $r3, $r4
	sti $r3, $r1, 0
	fldi $f0, $r1, 0
	fsub $f0, $f0, $f1
	return
ITOF_NEGATIVE_MAIN:
	sub $r3, $r0, $r3
	call ITOF_MAIN
	fneg $f0, $f0
	return

# * int_of_float
min_caml_int_of_float:
	# $f1 <- 0.0
	# fset $f1, 0.0
	fmvhi $f1, 0
	fmvlo $f1, 0
	fblt $f0, $f1, FTOI_NEGATIVE_MAIN			# if (0.0 <= $f0) goto FTOI_MAIN
FTOI_POSITIVE_MAIN:
	# call min_caml_floor # is it needed??
	# $f2 <- 8388608.0(0x4b000000)
	fmvhi $f2, 19200
	fmvlo $f2, 0
	# $r4 <- 0x4b000000
	mvhi $r4, 19200
	mvlo $r4, 0
	fblt $f0, $f2, FTOI_SMALL		# if (MAGICF <= $f0) goto FTOI_BIG
	# $r5 <- 0x00800000
	mvhi $r5, 128
	mvlo $r5, 0
	mov $r3, $r0
FTOI_LOOP:
	fsub $f0, $f0, $f2
	add $r3, $r3, $r5
	fblt $f0, $f2, FTOI_RET
	j FTOI_LOOP
FTOI_RET:
	fadd $f0, $f0, $f2
	fmovi $r5, $f0
	sub $r5, $r5, $r4
	add $r3, $r5, $r3
	return
FTOI_SMALL:
	fadd $f0, $f0, $f2
	fmovi $r3, $f0
	sub $r3, $r3, $r4
	return
FTOI_NEGATIVE_MAIN:
	fneg $f0, $f0
	call FTOI_POSITIVE_MAIN
	sub $r3, $r0, $r3
	return
	
# * truncate
min_caml_truncate:
	j min_caml_int_of_float
	
# ビッグエンディアン
min_caml_read_int:
	add $r3, $r0, $r0
	# 24 - 31
	inputb $r4
	add $r3, $r3, $r4
	slli $r3, $r3, 8
	# 16 - 23
	inputb $r4
	add $r3, $r3, $r4
	slli $r3, $r3, 8
	# 8 - 15
	inputb $r4
	add $r3, $r3, $r4
	slli $r3, $r3, 8
	# 0 - 7
	inputb $r4
	add $r3, $r3, $r4
	return

min_caml_read_float:
	call min_caml_read_int
	sti $r3, $r1, 0
	fldi $f0, $r1, 0
	return

#----------------------------------------------------------------------
#
# lib_asm.s
#
#----------------------------------------------------------------------


min_caml_start:
	mvhi	$r2, 0
	mvlo	$r2, 7
	addi	$r30, $r0, 1
	sub	$r31, $r0, $r30
	addi	$r1, $r0, 1024
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 7
	addi	$r2, $r0, 5
	subi	$r1, $r1, 1
	call	min_caml_create_array
	ldi	$r2, $r0, 7
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 7
	addi	$r2, $r0, 4
	call	min_caml_create_array
	ldi	$r2, $r0, 7
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 7
	addi	$r2, $r0, 3
	call	min_caml_create_array
	ldi	$r2, $r0, 7
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 7
	addi	$r2, $r0, 2
	call	min_caml_create_array
	ldi	$r2, $r0, 7
	addi	$r3, $r0, 1
	addi	$r4, $r0, 1
	sti	$r2, $r0, 7
	addi	$r2, $r0, 1
	call	min_caml_create_array
	ldi	$r2, $r0, 7
	addi	$r3, $r0, 1
	addi	$r4, $r0, 0
	sti	$r2, $r0, 7
	addi	$r2, $r0, 0
	call	min_caml_create_array
	ldi	$r2, $r0, 7
	addi	$r4, $r0, 7
	call	fib.378
	addi	$r1, $r1, 1
	mov	$r9, $r3
	addi	$r4, $r0, 6
	sti	$r9, $r1, 0
	subi	$r1, $r1, 2
	call	fib.378
	addi	$r1, $r1, 2
	ldi	$r9, $r1, 0
	add	$r11, $r9, $r3
	addi	$r4, $r0, 5
	sti	$r11, $r1, -1
	sti	$r3, $r1, -2
	subi	$r1, $r1, 4
	call	fib.378
	addi	$r1, $r1, 4
	mov	$r9, $r3
	ldi	$r3, $r1, -2
	add	$r10, $r3, $r9
	ldi	$r11, $r1, -1
	add	$r11, $r11, $r10
	addi	$r4, $r0, 4
	sti	$r11, $r1, -3
	sti	$r10, $r1, -4
	sti	$r9, $r1, -5
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	ldi	$r9, $r1, -5
	add	$r3, $r9, $r3
	ldi	$r10, $r1, -4
	add	$r3, $r10, $r3
	ldi	$r11, $r1, -3
	add	$r4, $r11, $r3
	subi	$r1, $r1, 7
	call	print_int.376
	addi	$r1, $r1, 7
	halt

#---------------------------------------------------------------------
# args = [$r4, $r6, $r8, $r9]
# fargs = []
# ret type = Int
#---------------------------------------------------------------------
div_binary_search.364:
	add	$r3, $r8, $r9
	srai	$r5, $r3, 1
	mul	$r7, $r5, $r6
	sub	$r3, $r9, $r8
	blt	$r30, $r3, ble_else.2077
	mov	$r3, $r8
	return
ble_else.2077:
	blt	$r7, $r4, ble_else.2078
	beq	$r7, $r4, bne_else.2079
	add	$r3, $r8, $r5
	srai	$r9, $r3, 1
	mul	$r7, $r9, $r6
	sub	$r3, $r5, $r8
	blt	$r30, $r3, ble_else.2080
	mov	$r3, $r8
	return
ble_else.2080:
	blt	$r7, $r4, ble_else.2081
	beq	$r7, $r4, bne_else.2082
	add	$r3, $r8, $r9
	srai	$r7, $r3, 1
	mul	$r5, $r7, $r6
	sub	$r3, $r9, $r8
	blt	$r30, $r3, ble_else.2083
	mov	$r3, $r8
	return
ble_else.2083:
	blt	$r5, $r4, ble_else.2084
	beq	$r5, $r4, bne_else.2085
	add	$r3, $r8, $r7
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r7, $r8
	blt	$r30, $r3, ble_else.2086
	mov	$r3, $r8
	return
ble_else.2086:
	blt	$r9, $r4, ble_else.2087
	beq	$r9, $r4, bne_else.2088
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.2088:
	mov	$r3, $r5
	return
ble_else.2087:
	mov	$r9, $r7
	mov	$r8, $r5
	j	div_binary_search.364
bne_else.2085:
	mov	$r3, $r7
	return
ble_else.2084:
	add	$r3, $r7, $r9
	srai	$r5, $r3, 1
	mul	$r8, $r5, $r6
	sub	$r3, $r9, $r7
	blt	$r30, $r3, ble_else.2089
	mov	$r3, $r7
	return
ble_else.2089:
	blt	$r8, $r4, ble_else.2090
	beq	$r8, $r4, bne_else.2091
	mov	$r9, $r5
	mov	$r8, $r7
	j	div_binary_search.364
bne_else.2091:
	mov	$r3, $r5
	return
ble_else.2090:
	mov	$r8, $r5
	j	div_binary_search.364
bne_else.2082:
	mov	$r3, $r9
	return
ble_else.2081:
	add	$r3, $r9, $r5
	srai	$r8, $r3, 1
	mul	$r7, $r8, $r6
	sub	$r3, $r5, $r9
	blt	$r30, $r3, ble_else.2092
	mov	$r3, $r9
	return
ble_else.2092:
	blt	$r7, $r4, ble_else.2093
	beq	$r7, $r4, bne_else.2094
	add	$r3, $r9, $r8
	srai	$r5, $r3, 1
	mul	$r7, $r5, $r6
	sub	$r3, $r8, $r9
	blt	$r30, $r3, ble_else.2095
	mov	$r3, $r9
	return
ble_else.2095:
	blt	$r7, $r4, ble_else.2096
	beq	$r7, $r4, bne_else.2097
	mov	$r8, $r9
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.2097:
	mov	$r3, $r5
	return
ble_else.2096:
	mov	$r9, $r8
	mov	$r8, $r5
	j	div_binary_search.364
bne_else.2094:
	mov	$r3, $r8
	return
ble_else.2093:
	add	$r3, $r8, $r5
	srai	$r7, $r3, 1
	mul	$r9, $r7, $r6
	sub	$r3, $r5, $r8
	blt	$r30, $r3, ble_else.2098
	mov	$r3, $r8
	return
ble_else.2098:
	blt	$r9, $r4, ble_else.2099
	beq	$r9, $r4, bne_else.2100
	mov	$r9, $r7
	j	div_binary_search.364
bne_else.2100:
	mov	$r3, $r7
	return
ble_else.2099:
	mov	$r9, $r5
	mov	$r8, $r7
	j	div_binary_search.364
bne_else.2079:
	mov	$r3, $r5
	return
ble_else.2078:
	add	$r3, $r5, $r9
	srai	$r8, $r3, 1
	mul	$r7, $r8, $r6
	sub	$r3, $r9, $r5
	blt	$r30, $r3, ble_else.2101
	mov	$r3, $r5
	return
ble_else.2101:
	blt	$r7, $r4, ble_else.2102
	beq	$r7, $r4, bne_else.2103
	add	$r3, $r5, $r8
	srai	$r7, $r3, 1
	mul	$r9, $r7, $r6
	sub	$r3, $r8, $r5
	blt	$r30, $r3, ble_else.2104
	mov	$r3, $r5
	return
ble_else.2104:
	blt	$r9, $r4, ble_else.2105
	beq	$r9, $r4, bne_else.2106
	add	$r3, $r5, $r7
	srai	$r8, $r3, 1
	mul	$r9, $r8, $r6
	sub	$r3, $r7, $r5
	blt	$r30, $r3, ble_else.2107
	mov	$r3, $r5
	return
ble_else.2107:
	blt	$r9, $r4, ble_else.2108
	beq	$r9, $r4, bne_else.2109
	mov	$r9, $r8
	mov	$r8, $r5
	j	div_binary_search.364
bne_else.2109:
	mov	$r3, $r8
	return
ble_else.2108:
	mov	$r9, $r7
	j	div_binary_search.364
bne_else.2106:
	mov	$r3, $r7
	return
ble_else.2105:
	add	$r3, $r7, $r8
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r8, $r7
	blt	$r30, $r3, ble_else.2110
	mov	$r3, $r7
	return
ble_else.2110:
	blt	$r9, $r4, ble_else.2111
	beq	$r9, $r4, bne_else.2112
	mov	$r9, $r5
	mov	$r8, $r7
	j	div_binary_search.364
bne_else.2112:
	mov	$r3, $r5
	return
ble_else.2111:
	mov	$r9, $r8
	mov	$r8, $r5
	j	div_binary_search.364
bne_else.2103:
	mov	$r3, $r8
	return
ble_else.2102:
	add	$r3, $r8, $r9
	srai	$r7, $r3, 1
	mul	$r5, $r7, $r6
	sub	$r3, $r9, $r8
	blt	$r30, $r3, ble_else.2113
	mov	$r3, $r8
	return
ble_else.2113:
	blt	$r5, $r4, ble_else.2114
	beq	$r5, $r4, bne_else.2115
	add	$r3, $r8, $r7
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r7, $r8
	blt	$r30, $r3, ble_else.2116
	mov	$r3, $r8
	return
ble_else.2116:
	blt	$r9, $r4, ble_else.2117
	beq	$r9, $r4, bne_else.2118
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.2118:
	mov	$r3, $r5
	return
ble_else.2117:
	mov	$r9, $r7
	mov	$r8, $r5
	j	div_binary_search.364
bne_else.2115:
	mov	$r3, $r7
	return
ble_else.2114:
	add	$r3, $r7, $r9
	srai	$r5, $r3, 1
	mul	$r8, $r5, $r6
	sub	$r3, $r9, $r7
	blt	$r30, $r3, ble_else.2119
	mov	$r3, $r7
	return
ble_else.2119:
	blt	$r8, $r4, ble_else.2120
	beq	$r8, $r4, bne_else.2121
	mov	$r9, $r5
	mov	$r8, $r7
	j	div_binary_search.364
bne_else.2121:
	mov	$r3, $r5
	return
ble_else.2120:
	mov	$r8, $r5
	j	div_binary_search.364

#---------------------------------------------------------------------
# args = [$r4]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
print_int.376:
	blt	$r4, $r0, bge_else.2122
	mvhi	$r3, 1525
	mvlo	$r3, 57600
	blt	$r3, $r4, ble_else.2123
	beq	$r3, $r4, bne_else.2125
	addi	$r5, $r0, 0
	j	bne_cont.2126
bne_else.2125:
	addi	$r5, $r0, 1
bne_cont.2126:
	j	ble_cont.2124
ble_else.2123:
	mvhi	$r3, 3051
	mvlo	$r3, 49664
	blt	$r3, $r4, ble_else.2127
	beq	$r3, $r4, bne_else.2129
	addi	$r5, $r0, 1
	j	bne_cont.2130
bne_else.2129:
	addi	$r5, $r0, 2
bne_cont.2130:
	j	ble_cont.2128
ble_else.2127:
	addi	$r5, $r0, 2
ble_cont.2128:
ble_cont.2124:
	mvhi	$r3, 1525
	mvlo	$r3, 57600
	mul	$r3, $r5, $r3
	sub	$r4, $r4, $r3
	blt	$r0, $r5, ble_else.2131
	addi	$r12, $r0, 0
	j	ble_cont.2132
ble_else.2131:
	addi	$r3, $r0, 48
	add	$r3, $r3, $r5
	outputb	$r3
	addi	$r12, $r0, 1
ble_cont.2132:
	mvhi	$r6, 152
	mvlo	$r6, 38528
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 762
	mvlo	$r5, 61568
	sti	$r4, $r1, 0
	blt	$r5, $r4, ble_else.2133
	beq	$r5, $r4, bne_else.2135
	addi	$r8, $r0, 2
	mvhi	$r5, 305
	mvlo	$r5, 11520
	blt	$r5, $r4, ble_else.2137
	beq	$r5, $r4, bne_else.2139
	addi	$r9, $r0, 1
	mvhi	$r5, 152
	mvlo	$r5, 38528
	blt	$r5, $r4, ble_else.2141
	beq	$r5, $r4, bne_else.2143
	mov	$r8, $r11
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.2144
bne_else.2143:
	addi	$r3, $r0, 1
bne_cont.2144:
	j	ble_cont.2142
ble_else.2141:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.2142:
	j	bne_cont.2140
bne_else.2139:
	addi	$r3, $r0, 2
bne_cont.2140:
	j	ble_cont.2138
ble_else.2137:
	addi	$r10, $r0, 3
	mvhi	$r5, 457
	mvlo	$r5, 50048
	blt	$r5, $r4, ble_else.2145
	beq	$r5, $r4, bne_else.2147
	mov	$r9, $r10
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.2148
bne_else.2147:
	addi	$r3, $r0, 3
bne_cont.2148:
	j	ble_cont.2146
ble_else.2145:
	mov	$r8, $r10
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.2146:
ble_cont.2138:
	j	bne_cont.2136
bne_else.2135:
	addi	$r3, $r0, 5
bne_cont.2136:
	j	ble_cont.2134
ble_else.2133:
	addi	$r8, $r0, 7
	mvhi	$r5, 1068
	mvlo	$r5, 7552
	blt	$r5, $r4, ble_else.2149
	beq	$r5, $r4, bne_else.2151
	addi	$r10, $r0, 6
	mvhi	$r5, 915
	mvlo	$r5, 34560
	blt	$r5, $r4, ble_else.2153
	beq	$r5, $r4, bne_else.2155
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.2156
bne_else.2155:
	addi	$r3, $r0, 6
bne_cont.2156:
	j	ble_cont.2154
ble_else.2153:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.2154:
	j	bne_cont.2152
bne_else.2151:
	addi	$r3, $r0, 7
bne_cont.2152:
	j	ble_cont.2150
ble_else.2149:
	addi	$r9, $r0, 8
	mvhi	$r5, 1220
	mvlo	$r5, 46080
	blt	$r5, $r4, ble_else.2157
	beq	$r5, $r4, bne_else.2159
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.2160
bne_else.2159:
	addi	$r3, $r0, 8
bne_cont.2160:
	j	ble_cont.2158
ble_else.2157:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.2158:
ble_cont.2150:
ble_cont.2134:
	mvhi	$r5, 152
	mvlo	$r5, 38528
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, 0
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2161
	beq	$r12, $r0, bne_else.2163
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.2164
bne_else.2163:
	addi	$r13, $r0, 0
bne_cont.2164:
	j	ble_cont.2162
ble_else.2161:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.2162:
	mvhi	$r6, 15
	mvlo	$r6, 16960
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 76
	mvlo	$r5, 19264
	sti	$r4, $r1, -1
	blt	$r5, $r4, ble_else.2165
	beq	$r5, $r4, bne_else.2167
	addi	$r8, $r0, 2
	mvhi	$r5, 30
	mvlo	$r5, 33920
	blt	$r5, $r4, ble_else.2169
	beq	$r5, $r4, bne_else.2171
	addi	$r9, $r0, 1
	mvhi	$r5, 15
	mvlo	$r5, 16960
	blt	$r5, $r4, ble_else.2173
	beq	$r5, $r4, bne_else.2175
	mov	$r8, $r11
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2176
bne_else.2175:
	addi	$r3, $r0, 1
bne_cont.2176:
	j	ble_cont.2174
ble_else.2173:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2174:
	j	bne_cont.2172
bne_else.2171:
	addi	$r3, $r0, 2
bne_cont.2172:
	j	ble_cont.2170
ble_else.2169:
	addi	$r10, $r0, 3
	mvhi	$r5, 45
	mvlo	$r5, 50880
	blt	$r5, $r4, ble_else.2177
	beq	$r5, $r4, bne_else.2179
	mov	$r9, $r10
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2180
bne_else.2179:
	addi	$r3, $r0, 3
bne_cont.2180:
	j	ble_cont.2178
ble_else.2177:
	mov	$r8, $r10
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2178:
ble_cont.2170:
	j	bne_cont.2168
bne_else.2167:
	addi	$r3, $r0, 5
bne_cont.2168:
	j	ble_cont.2166
ble_else.2165:
	addi	$r8, $r0, 7
	mvhi	$r5, 106
	mvlo	$r5, 53184
	blt	$r5, $r4, ble_else.2181
	beq	$r5, $r4, bne_else.2183
	addi	$r10, $r0, 6
	mvhi	$r5, 91
	mvlo	$r5, 36224
	blt	$r5, $r4, ble_else.2185
	beq	$r5, $r4, bne_else.2187
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2188
bne_else.2187:
	addi	$r3, $r0, 6
bne_cont.2188:
	j	ble_cont.2186
ble_else.2185:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2186:
	j	bne_cont.2184
bne_else.2183:
	addi	$r3, $r0, 7
bne_cont.2184:
	j	ble_cont.2182
ble_else.2181:
	addi	$r9, $r0, 8
	mvhi	$r5, 122
	mvlo	$r5, 4608
	blt	$r5, $r4, ble_else.2189
	beq	$r5, $r4, bne_else.2191
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2192
bne_else.2191:
	addi	$r3, $r0, 8
bne_cont.2192:
	j	ble_cont.2190
ble_else.2189:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2190:
ble_cont.2182:
ble_cont.2166:
	mvhi	$r5, 15
	mvlo	$r5, 16960
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -1
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2193
	beq	$r13, $r0, bne_else.2195
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r12, $r0, 1
	j	bne_cont.2196
bne_else.2195:
	addi	$r12, $r0, 0
bne_cont.2196:
	j	ble_cont.2194
ble_else.2193:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r12, $r0, 1
ble_cont.2194:
	mvhi	$r6, 1
	mvlo	$r6, 34464
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 7
	mvlo	$r5, 41248
	sti	$r4, $r1, -2
	blt	$r5, $r4, ble_else.2197
	beq	$r5, $r4, bne_else.2199
	addi	$r8, $r0, 2
	mvhi	$r5, 3
	mvlo	$r5, 3392
	blt	$r5, $r4, ble_else.2201
	beq	$r5, $r4, bne_else.2203
	addi	$r9, $r0, 1
	mvhi	$r5, 1
	mvlo	$r5, 34464
	blt	$r5, $r4, ble_else.2205
	beq	$r5, $r4, bne_else.2207
	mov	$r8, $r11
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2208
bne_else.2207:
	addi	$r3, $r0, 1
bne_cont.2208:
	j	ble_cont.2206
ble_else.2205:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2206:
	j	bne_cont.2204
bne_else.2203:
	addi	$r3, $r0, 2
bne_cont.2204:
	j	ble_cont.2202
ble_else.2201:
	addi	$r10, $r0, 3
	mvhi	$r5, 4
	mvlo	$r5, 37856
	blt	$r5, $r4, ble_else.2209
	beq	$r5, $r4, bne_else.2211
	mov	$r9, $r10
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2212
bne_else.2211:
	addi	$r3, $r0, 3
bne_cont.2212:
	j	ble_cont.2210
ble_else.2209:
	mov	$r8, $r10
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2210:
ble_cont.2202:
	j	bne_cont.2200
bne_else.2199:
	addi	$r3, $r0, 5
bne_cont.2200:
	j	ble_cont.2198
ble_else.2197:
	addi	$r8, $r0, 7
	mvhi	$r5, 10
	mvlo	$r5, 44640
	blt	$r5, $r4, ble_else.2213
	beq	$r5, $r4, bne_else.2215
	addi	$r10, $r0, 6
	mvhi	$r5, 9
	mvlo	$r5, 10176
	blt	$r5, $r4, ble_else.2217
	beq	$r5, $r4, bne_else.2219
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2220
bne_else.2219:
	addi	$r3, $r0, 6
bne_cont.2220:
	j	ble_cont.2218
ble_else.2217:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2218:
	j	bne_cont.2216
bne_else.2215:
	addi	$r3, $r0, 7
bne_cont.2216:
	j	ble_cont.2214
ble_else.2213:
	addi	$r9, $r0, 8
	mvhi	$r5, 12
	mvlo	$r5, 13568
	blt	$r5, $r4, ble_else.2221
	beq	$r5, $r4, bne_else.2223
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2224
bne_else.2223:
	addi	$r3, $r0, 8
bne_cont.2224:
	j	ble_cont.2222
ble_else.2221:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2222:
ble_cont.2214:
ble_cont.2198:
	mvhi	$r5, 1
	mvlo	$r5, 34464
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -2
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2225
	beq	$r12, $r0, bne_else.2227
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.2228
bne_else.2227:
	addi	$r13, $r0, 0
bne_cont.2228:
	j	ble_cont.2226
ble_else.2225:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.2226:
	addi	$r6, $r0, 10000
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	mvhi	$r5, 0
	mvlo	$r5, 50000
	sti	$r4, $r1, -3
	blt	$r5, $r4, ble_else.2229
	beq	$r5, $r4, bne_else.2231
	addi	$r8, $r0, 2
	addi	$r5, $r0, 20000
	blt	$r5, $r4, ble_else.2233
	beq	$r5, $r4, bne_else.2235
	addi	$r9, $r0, 1
	addi	$r5, $r0, 10000
	blt	$r5, $r4, ble_else.2237
	beq	$r5, $r4, bne_else.2239
	mov	$r8, $r11
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2240
bne_else.2239:
	addi	$r3, $r0, 1
bne_cont.2240:
	j	ble_cont.2238
ble_else.2237:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2238:
	j	bne_cont.2236
bne_else.2235:
	addi	$r3, $r0, 2
bne_cont.2236:
	j	ble_cont.2234
ble_else.2233:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 30000
	blt	$r5, $r4, ble_else.2241
	beq	$r5, $r4, bne_else.2243
	mov	$r9, $r10
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2244
bne_else.2243:
	addi	$r3, $r0, 3
bne_cont.2244:
	j	ble_cont.2242
ble_else.2241:
	mov	$r8, $r10
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2242:
ble_cont.2234:
	j	bne_cont.2232
bne_else.2231:
	addi	$r3, $r0, 5
bne_cont.2232:
	j	ble_cont.2230
ble_else.2229:
	addi	$r8, $r0, 7
	mvhi	$r5, 1
	mvlo	$r5, 4464
	blt	$r5, $r4, ble_else.2245
	beq	$r5, $r4, bne_else.2247
	addi	$r10, $r0, 6
	mvhi	$r5, 0
	mvlo	$r5, 60000
	blt	$r5, $r4, ble_else.2249
	beq	$r5, $r4, bne_else.2251
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2252
bne_else.2251:
	addi	$r3, $r0, 6
bne_cont.2252:
	j	ble_cont.2250
ble_else.2249:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2250:
	j	bne_cont.2248
bne_else.2247:
	addi	$r3, $r0, 7
bne_cont.2248:
	j	ble_cont.2246
ble_else.2245:
	addi	$r9, $r0, 8
	mvhi	$r5, 1
	mvlo	$r5, 14464
	blt	$r5, $r4, ble_else.2253
	beq	$r5, $r4, bne_else.2255
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2256
bne_else.2255:
	addi	$r3, $r0, 8
bne_cont.2256:
	j	ble_cont.2254
ble_else.2253:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2254:
ble_cont.2246:
ble_cont.2230:
	addi	$r5, $r0, 10000
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -3
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2257
	beq	$r13, $r0, bne_else.2259
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r12, $r0, 1
	j	bne_cont.2260
bne_else.2259:
	addi	$r12, $r0, 0
bne_cont.2260:
	j	ble_cont.2258
ble_else.2257:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r12, $r0, 1
ble_cont.2258:
	addi	$r6, $r0, 1000
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	addi	$r5, $r0, 5000
	sti	$r4, $r1, -4
	blt	$r5, $r4, ble_else.2261
	beq	$r5, $r4, bne_else.2263
	addi	$r8, $r0, 2
	addi	$r5, $r0, 2000
	blt	$r5, $r4, ble_else.2265
	beq	$r5, $r4, bne_else.2267
	addi	$r9, $r0, 1
	addi	$r5, $r0, 1000
	blt	$r5, $r4, ble_else.2269
	beq	$r5, $r4, bne_else.2271
	mov	$r8, $r11
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2272
bne_else.2271:
	addi	$r3, $r0, 1
bne_cont.2272:
	j	ble_cont.2270
ble_else.2269:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2270:
	j	bne_cont.2268
bne_else.2267:
	addi	$r3, $r0, 2
bne_cont.2268:
	j	ble_cont.2266
ble_else.2265:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 3000
	blt	$r5, $r4, ble_else.2273
	beq	$r5, $r4, bne_else.2275
	mov	$r9, $r10
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2276
bne_else.2275:
	addi	$r3, $r0, 3
bne_cont.2276:
	j	ble_cont.2274
ble_else.2273:
	mov	$r8, $r10
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2274:
ble_cont.2266:
	j	bne_cont.2264
bne_else.2263:
	addi	$r3, $r0, 5
bne_cont.2264:
	j	ble_cont.2262
ble_else.2261:
	addi	$r8, $r0, 7
	addi	$r5, $r0, 7000
	blt	$r5, $r4, ble_else.2277
	beq	$r5, $r4, bne_else.2279
	addi	$r10, $r0, 6
	addi	$r5, $r0, 6000
	blt	$r5, $r4, ble_else.2281
	beq	$r5, $r4, bne_else.2283
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2284
bne_else.2283:
	addi	$r3, $r0, 6
bne_cont.2284:
	j	ble_cont.2282
ble_else.2281:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2282:
	j	bne_cont.2280
bne_else.2279:
	addi	$r3, $r0, 7
bne_cont.2280:
	j	ble_cont.2278
ble_else.2277:
	addi	$r9, $r0, 8
	addi	$r5, $r0, 8000
	blt	$r5, $r4, ble_else.2285
	beq	$r5, $r4, bne_else.2287
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2288
bne_else.2287:
	addi	$r3, $r0, 8
bne_cont.2288:
	j	ble_cont.2286
ble_else.2285:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2286:
ble_cont.2278:
ble_cont.2262:
	muli	$r5, $r3, 1000
	ldi	$r4, $r1, -4
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2289
	beq	$r12, $r0, bne_else.2291
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.2292
bne_else.2291:
	addi	$r13, $r0, 0
bne_cont.2292:
	j	ble_cont.2290
ble_else.2289:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.2290:
	addi	$r6, $r0, 100
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	addi	$r5, $r0, 500
	sti	$r4, $r1, -5
	blt	$r5, $r4, ble_else.2293
	beq	$r5, $r4, bne_else.2295
	addi	$r8, $r0, 2
	addi	$r5, $r0, 200
	blt	$r5, $r4, ble_else.2297
	beq	$r5, $r4, bne_else.2299
	addi	$r9, $r0, 1
	addi	$r5, $r0, 100
	blt	$r5, $r4, ble_else.2301
	beq	$r5, $r4, bne_else.2303
	mov	$r8, $r11
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2304
bne_else.2303:
	addi	$r3, $r0, 1
bne_cont.2304:
	j	ble_cont.2302
ble_else.2301:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2302:
	j	bne_cont.2300
bne_else.2299:
	addi	$r3, $r0, 2
bne_cont.2300:
	j	ble_cont.2298
ble_else.2297:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 300
	blt	$r5, $r4, ble_else.2305
	beq	$r5, $r4, bne_else.2307
	mov	$r9, $r10
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2308
bne_else.2307:
	addi	$r3, $r0, 3
bne_cont.2308:
	j	ble_cont.2306
ble_else.2305:
	mov	$r8, $r10
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2306:
ble_cont.2298:
	j	bne_cont.2296
bne_else.2295:
	addi	$r3, $r0, 5
bne_cont.2296:
	j	ble_cont.2294
ble_else.2293:
	addi	$r8, $r0, 7
	addi	$r5, $r0, 700
	blt	$r5, $r4, ble_else.2309
	beq	$r5, $r4, bne_else.2311
	addi	$r10, $r0, 6
	addi	$r5, $r0, 600
	blt	$r5, $r4, ble_else.2313
	beq	$r5, $r4, bne_else.2315
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2316
bne_else.2315:
	addi	$r3, $r0, 6
bne_cont.2316:
	j	ble_cont.2314
ble_else.2313:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2314:
	j	bne_cont.2312
bne_else.2311:
	addi	$r3, $r0, 7
bne_cont.2312:
	j	ble_cont.2310
ble_else.2309:
	addi	$r9, $r0, 8
	addi	$r5, $r0, 800
	blt	$r5, $r4, ble_else.2317
	beq	$r5, $r4, bne_else.2319
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2320
bne_else.2319:
	addi	$r3, $r0, 8
bne_cont.2320:
	j	ble_cont.2318
ble_else.2317:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2318:
ble_cont.2310:
ble_cont.2294:
	muli	$r5, $r3, 100
	ldi	$r4, $r1, -5
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2321
	beq	$r13, $r0, bne_else.2323
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r12, $r0, 1
	j	bne_cont.2324
bne_else.2323:
	addi	$r12, $r0, 0
bne_cont.2324:
	j	ble_cont.2322
ble_else.2321:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r12, $r0, 1
ble_cont.2322:
	addi	$r6, $r0, 10
	addi	$r11, $r0, 0
	addi	$r10, $r0, 10
	addi	$r9, $r0, 5
	addi	$r5, $r0, 50
	sti	$r4, $r1, -6
	blt	$r5, $r4, ble_else.2325
	beq	$r5, $r4, bne_else.2327
	addi	$r8, $r0, 2
	addi	$r5, $r0, 20
	blt	$r5, $r4, ble_else.2329
	beq	$r5, $r4, bne_else.2331
	addi	$r9, $r0, 1
	addi	$r5, $r0, 10
	blt	$r5, $r4, ble_else.2333
	beq	$r5, $r4, bne_else.2335
	mov	$r8, $r11
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2336
bne_else.2335:
	addi	$r3, $r0, 1
bne_cont.2336:
	j	ble_cont.2334
ble_else.2333:
	mov	$r28, $r9
	mov	$r9, $r8
	mov	$r8, $r28
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2334:
	j	bne_cont.2332
bne_else.2331:
	addi	$r3, $r0, 2
bne_cont.2332:
	j	ble_cont.2330
ble_else.2329:
	addi	$r10, $r0, 3
	addi	$r5, $r0, 30
	blt	$r5, $r4, ble_else.2337
	beq	$r5, $r4, bne_else.2339
	mov	$r9, $r10
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2340
bne_else.2339:
	addi	$r3, $r0, 3
bne_cont.2340:
	j	ble_cont.2338
ble_else.2337:
	mov	$r8, $r10
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2338:
ble_cont.2330:
	j	bne_cont.2328
bne_else.2327:
	addi	$r3, $r0, 5
bne_cont.2328:
	j	ble_cont.2326
ble_else.2325:
	addi	$r8, $r0, 7
	addi	$r5, $r0, 70
	blt	$r5, $r4, ble_else.2341
	beq	$r5, $r4, bne_else.2343
	addi	$r10, $r0, 6
	addi	$r5, $r0, 60
	blt	$r5, $r4, ble_else.2345
	beq	$r5, $r4, bne_else.2347
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2348
bne_else.2347:
	addi	$r3, $r0, 6
bne_cont.2348:
	j	ble_cont.2346
ble_else.2345:
	mov	$r9, $r8
	mov	$r8, $r10
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2346:
	j	bne_cont.2344
bne_else.2343:
	addi	$r3, $r0, 7
bne_cont.2344:
	j	ble_cont.2342
ble_else.2341:
	addi	$r9, $r0, 8
	addi	$r5, $r0, 80
	blt	$r5, $r4, ble_else.2349
	beq	$r5, $r4, bne_else.2351
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2352
bne_else.2351:
	addi	$r3, $r0, 8
bne_cont.2352:
	j	ble_cont.2350
ble_else.2349:
	mov	$r8, $r9
	mov	$r9, $r10
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2350:
ble_cont.2342:
ble_cont.2326:
	muli	$r5, $r3, 10
	ldi	$r4, $r1, -6
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2353
	beq	$r12, $r0, bne_else.2355
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r5, $r0, 1
	j	bne_cont.2356
bne_else.2355:
	addi	$r5, $r0, 0
bne_cont.2356:
	j	ble_cont.2354
ble_else.2353:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r5, $r0, 1
ble_cont.2354:
	addi	$r3, $r0, 48
	add	$r3, $r3, $r4
	outputb	$r3
	return
bge_else.2122:
	addi	$r3, $r0, 45
	outputb	$r3
	sub	$r4, $r0, $r4
	j	print_int.376

#---------------------------------------------------------------------
# args = [$r4]
# fargs = []
# ret type = Int
#---------------------------------------------------------------------
fib.378:
	blt	$r30, $r4, ble_else.2357
	mov	$r3, $r4
	return
ble_else.2357:
	subi	$r8, $r4, 1
	sti	$r4, $r1, 0
	blt	$r30, $r8, ble_else.2358
	mov	$r3, $r8
	j	ble_cont.2359
ble_else.2358:
	subi	$r5, $r8, 1
	sti	$r8, $r1, -1
	blt	$r30, $r5, ble_else.2360
	mov	$r7, $r5
	j	ble_cont.2361
ble_else.2360:
	subi	$r3, $r5, 1
	sti	$r5, $r1, -2
	blt	$r30, $r3, ble_else.2362
	mov	$r6, $r3
	j	ble_cont.2363
ble_else.2362:
	subi	$r6, $r3, 1
	sti	$r3, $r1, -3
	mov	$r4, $r6
	subi	$r1, $r1, 5
	call	fib.378
	addi	$r1, $r1, 5
	mov	$r6, $r3
	ldi	$r3, $r1, -3
	subi	$r3, $r3, 2
	sti	$r6, $r1, -4
	mov	$r4, $r3
	subi	$r1, $r1, 6
	call	fib.378
	addi	$r1, $r1, 6
	ldi	$r6, $r1, -4
	add	$r6, $r6, $r3
ble_cont.2363:
	ldi	$r5, $r1, -2
	subi	$r5, $r5, 2
	sti	$r6, $r1, -3
	blt	$r30, $r5, ble_else.2364
	mov	$r3, $r5
	j	ble_cont.2365
ble_else.2364:
	subi	$r3, $r5, 1
	sti	$r5, $r1, -4
	mov	$r4, $r3
	subi	$r1, $r1, 6
	call	fib.378
	addi	$r1, $r1, 6
	mov	$r7, $r3
	ldi	$r5, $r1, -4
	subi	$r3, $r5, 2
	sti	$r7, $r1, -5
	mov	$r4, $r3
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	ldi	$r7, $r1, -5
	add	$r3, $r7, $r3
ble_cont.2365:
	ldi	$r6, $r1, -3
	add	$r7, $r6, $r3
ble_cont.2361:
	ldi	$r8, $r1, -1
	subi	$r5, $r8, 2
	sti	$r7, $r1, -2
	blt	$r30, $r5, ble_else.2366
	mov	$r3, $r5
	j	ble_cont.2367
ble_else.2366:
	subi	$r3, $r5, 1
	sti	$r5, $r1, -3
	blt	$r30, $r3, ble_else.2368
	mov	$r6, $r3
	j	ble_cont.2369
ble_else.2368:
	subi	$r6, $r3, 1
	sti	$r3, $r1, -4
	mov	$r4, $r6
	subi	$r1, $r1, 6
	call	fib.378
	addi	$r1, $r1, 6
	mov	$r6, $r3
	ldi	$r3, $r1, -4
	subi	$r3, $r3, 2
	sti	$r6, $r1, -5
	mov	$r4, $r3
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	ldi	$r6, $r1, -5
	add	$r6, $r6, $r3
ble_cont.2369:
	ldi	$r5, $r1, -3
	subi	$r5, $r5, 2
	sti	$r6, $r1, -4
	blt	$r30, $r5, ble_else.2370
	mov	$r3, $r5
	j	ble_cont.2371
ble_else.2370:
	subi	$r3, $r5, 1
	sti	$r5, $r1, -5
	mov	$r4, $r3
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	mov	$r8, $r3
	ldi	$r5, $r1, -5
	subi	$r3, $r5, 2
	sti	$r8, $r1, -6
	mov	$r4, $r3
	subi	$r1, $r1, 8
	call	fib.378
	addi	$r1, $r1, 8
	ldi	$r8, $r1, -6
	add	$r3, $r8, $r3
ble_cont.2371:
	ldi	$r6, $r1, -4
	add	$r3, $r6, $r3
ble_cont.2367:
	ldi	$r7, $r1, -2
	add	$r3, $r7, $r3
ble_cont.2359:
	ldi	$r4, $r1, 0
	subi	$r8, $r4, 2
	sti	$r3, $r1, -1
	blt	$r30, $r8, ble_else.2372
	mov	$r4, $r8
	j	ble_cont.2373
ble_else.2372:
	subi	$r5, $r8, 1
	sti	$r8, $r1, -2
	blt	$r30, $r5, ble_else.2374
	mov	$r7, $r5
	j	ble_cont.2375
ble_else.2374:
	subi	$r4, $r5, 1
	sti	$r5, $r1, -3
	blt	$r30, $r4, ble_else.2376
	mov	$r6, $r4
	j	ble_cont.2377
ble_else.2376:
	subi	$r6, $r4, 1
	sti	$r4, $r1, -4
	mov	$r4, $r6
	subi	$r1, $r1, 6
	call	fib.378
	addi	$r1, $r1, 6
	mov	$r7, $r3
	ldi	$r4, $r1, -4
	subi	$r4, $r4, 2
	sti	$r7, $r1, -5
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	mov	$r6, $r3
	ldi	$r7, $r1, -5
	add	$r6, $r7, $r6
ble_cont.2377:
	ldi	$r5, $r1, -3
	subi	$r5, $r5, 2
	sti	$r6, $r1, -4
	blt	$r30, $r5, ble_else.2378
	mov	$r4, $r5
	j	ble_cont.2379
ble_else.2378:
	subi	$r4, $r5, 1
	sti	$r5, $r1, -5
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	mov	$r7, $r3
	ldi	$r5, $r1, -5
	subi	$r4, $r5, 2
	sti	$r7, $r1, -6
	subi	$r1, $r1, 8
	call	fib.378
	addi	$r1, $r1, 8
	mov	$r4, $r3
	ldi	$r7, $r1, -6
	add	$r4, $r7, $r4
ble_cont.2379:
	ldi	$r6, $r1, -4
	add	$r7, $r6, $r4
ble_cont.2375:
	ldi	$r8, $r1, -2
	subi	$r5, $r8, 2
	sti	$r7, $r1, -3
	blt	$r30, $r5, ble_else.2380
	mov	$r4, $r5
	j	ble_cont.2381
ble_else.2380:
	subi	$r4, $r5, 1
	sti	$r5, $r1, -4
	blt	$r30, $r4, ble_else.2382
	mov	$r6, $r4
	j	ble_cont.2383
ble_else.2382:
	subi	$r6, $r4, 1
	sti	$r4, $r1, -5
	mov	$r4, $r6
	subi	$r1, $r1, 7
	call	fib.378
	addi	$r1, $r1, 7
	mov	$r8, $r3
	ldi	$r4, $r1, -5
	subi	$r4, $r4, 2
	sti	$r8, $r1, -6
	subi	$r1, $r1, 8
	call	fib.378
	addi	$r1, $r1, 8
	mov	$r6, $r3
	ldi	$r8, $r1, -6
	add	$r6, $r8, $r6
ble_cont.2383:
	ldi	$r5, $r1, -4
	subi	$r5, $r5, 2
	sti	$r6, $r1, -5
	blt	$r30, $r5, ble_else.2384
	mov	$r4, $r5
	j	ble_cont.2385
ble_else.2384:
	subi	$r4, $r5, 1
	sti	$r5, $r1, -6
	subi	$r1, $r1, 8
	call	fib.378
	addi	$r1, $r1, 8
	mov	$r8, $r3
	ldi	$r5, $r1, -6
	subi	$r4, $r5, 2
	sti	$r8, $r1, -7
	subi	$r1, $r1, 9
	call	fib.378
	addi	$r1, $r1, 9
	mov	$r4, $r3
	ldi	$r8, $r1, -7
	add	$r4, $r8, $r4
ble_cont.2385:
	ldi	$r6, $r1, -5
	add	$r4, $r6, $r4
ble_cont.2381:
	ldi	$r7, $r1, -3
	add	$r4, $r7, $r4
ble_cont.2373:
	ldi	$r3, $r1, -1
	add	$r3, $r3, $r4
	return
