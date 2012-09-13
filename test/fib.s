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
	call min_caml_floor
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
	fsti $f0, $r1, 0
	ldi $r5, $r1, 0
	sub $r5, $r5, $r4
	add $r3, $r5, $r3
	return
FTOI_SMALL:
	fadd $f0, $f0, $f2
	fsti $f0, $r1, 0
	ldi $r3, $r1, 0
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
	addi	$r4, $r0, 1
	call	print_int.376
	addi	$r1, $r1, 1
	halt

#---------------------------------------------------------------------
# args = [$r4, $r6, $r9, $r10]
# fargs = []
# ret type = Int
#---------------------------------------------------------------------
div_binary_search.364:
	add	$r3, $r9, $r10
	srai	$r5, $r3, 1
	mul	$r7, $r5, $r6
	sub	$r3, $r10, $r9
	blt	$r30, $r3, ble_else.1911
	mov	$r3, $r9
	return
ble_else.1911:
	blt	$r7, $r4, ble_else.1912
	beq	$r7, $r4, bne_else.1913
	add	$r3, $r9, $r5
	srai	$r8, $r3, 1
	mul	$r7, $r8, $r6
	sub	$r3, $r5, $r9
	blt	$r30, $r3, ble_else.1914
	mov	$r3, $r9
	return
ble_else.1914:
	blt	$r7, $r4, ble_else.1915
	beq	$r7, $r4, bne_else.1916
	add	$r3, $r9, $r8
	srai	$r7, $r3, 1
	mul	$r5, $r7, $r6
	sub	$r3, $r8, $r9
	blt	$r30, $r3, ble_else.1917
	mov	$r3, $r9
	return
ble_else.1917:
	blt	$r5, $r4, ble_else.1918
	beq	$r5, $r4, bne_else.1919
	add	$r3, $r9, $r7
	srai	$r5, $r3, 1
	mul	$r8, $r5, $r6
	sub	$r3, $r7, $r9
	blt	$r30, $r3, ble_else.1920
	mov	$r3, $r9
	return
ble_else.1920:
	blt	$r8, $r4, ble_else.1921
	beq	$r8, $r4, bne_else.1922
	mov	$r10, $r5
	j	div_binary_search.364
bne_else.1922:
	mov	$r3, $r5
	return
ble_else.1921:
	mov	$r10, $r7
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.1919:
	mov	$r3, $r7
	return
ble_else.1918:
	add	$r3, $r7, $r8
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r8, $r7
	blt	$r30, $r3, ble_else.1923
	mov	$r3, $r7
	return
ble_else.1923:
	blt	$r9, $r4, ble_else.1924
	beq	$r9, $r4, bne_else.1925
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.364
bne_else.1925:
	mov	$r3, $r5
	return
ble_else.1924:
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.1916:
	mov	$r3, $r8
	return
ble_else.1915:
	add	$r3, $r8, $r5
	srai	$r7, $r3, 1
	mul	$r9, $r7, $r6
	sub	$r3, $r5, $r8
	blt	$r30, $r3, ble_else.1926
	mov	$r3, $r8
	return
ble_else.1926:
	blt	$r9, $r4, ble_else.1927
	beq	$r9, $r4, bne_else.1928
	add	$r3, $r8, $r7
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r7, $r8
	blt	$r30, $r3, ble_else.1929
	mov	$r3, $r8
	return
ble_else.1929:
	blt	$r9, $r4, ble_else.1930
	beq	$r9, $r4, bne_else.1931
	mov	$r10, $r5
	mov	$r9, $r8
	j	div_binary_search.364
bne_else.1931:
	mov	$r3, $r5
	return
ble_else.1930:
	mov	$r10, $r7
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.1928:
	mov	$r3, $r7
	return
ble_else.1927:
	add	$r3, $r7, $r5
	srai	$r8, $r3, 1
	mul	$r9, $r8, $r6
	sub	$r3, $r5, $r7
	blt	$r30, $r3, ble_else.1932
	mov	$r3, $r7
	return
ble_else.1932:
	blt	$r9, $r4, ble_else.1933
	beq	$r9, $r4, bne_else.1934
	mov	$r10, $r8
	mov	$r9, $r7
	j	div_binary_search.364
bne_else.1934:
	mov	$r3, $r8
	return
ble_else.1933:
	mov	$r10, $r5
	mov	$r9, $r8
	j	div_binary_search.364
bne_else.1913:
	mov	$r3, $r5
	return
ble_else.1912:
	add	$r3, $r5, $r10
	srai	$r8, $r3, 1
	mul	$r7, $r8, $r6
	sub	$r3, $r10, $r5
	blt	$r30, $r3, ble_else.1935
	mov	$r3, $r5
	return
ble_else.1935:
	blt	$r7, $r4, ble_else.1936
	beq	$r7, $r4, bne_else.1937
	add	$r3, $r5, $r8
	srai	$r7, $r3, 1
	mul	$r9, $r7, $r6
	sub	$r3, $r8, $r5
	blt	$r30, $r3, ble_else.1938
	mov	$r3, $r5
	return
ble_else.1938:
	blt	$r9, $r4, ble_else.1939
	beq	$r9, $r4, bne_else.1940
	add	$r3, $r5, $r7
	srai	$r8, $r3, 1
	mul	$r9, $r8, $r6
	sub	$r3, $r7, $r5
	blt	$r30, $r3, ble_else.1941
	mov	$r3, $r5
	return
ble_else.1941:
	blt	$r9, $r4, ble_else.1942
	beq	$r9, $r4, bne_else.1943
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.1943:
	mov	$r3, $r8
	return
ble_else.1942:
	mov	$r10, $r7
	mov	$r9, $r8
	j	div_binary_search.364
bne_else.1940:
	mov	$r3, $r7
	return
ble_else.1939:
	add	$r3, $r7, $r8
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r8, $r7
	blt	$r30, $r3, ble_else.1944
	mov	$r3, $r7
	return
ble_else.1944:
	blt	$r9, $r4, ble_else.1945
	beq	$r9, $r4, bne_else.1946
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.364
bne_else.1946:
	mov	$r3, $r5
	return
ble_else.1945:
	mov	$r10, $r8
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.1937:
	mov	$r3, $r8
	return
ble_else.1936:
	add	$r3, $r8, $r10
	srai	$r7, $r3, 1
	mul	$r5, $r7, $r6
	sub	$r3, $r10, $r8
	blt	$r30, $r3, ble_else.1947
	mov	$r3, $r8
	return
ble_else.1947:
	blt	$r5, $r4, ble_else.1948
	beq	$r5, $r4, bne_else.1949
	add	$r3, $r8, $r7
	srai	$r5, $r3, 1
	mul	$r9, $r5, $r6
	sub	$r3, $r7, $r8
	blt	$r30, $r3, ble_else.1950
	mov	$r3, $r8
	return
ble_else.1950:
	blt	$r9, $r4, ble_else.1951
	beq	$r9, $r4, bne_else.1952
	mov	$r10, $r5
	mov	$r9, $r8
	j	div_binary_search.364
bne_else.1952:
	mov	$r3, $r5
	return
ble_else.1951:
	mov	$r10, $r7
	mov	$r9, $r5
	j	div_binary_search.364
bne_else.1949:
	mov	$r3, $r7
	return
ble_else.1948:
	add	$r3, $r7, $r10
	srai	$r5, $r3, 1
	mul	$r8, $r5, $r6
	sub	$r3, $r10, $r7
	blt	$r30, $r3, ble_else.1953
	mov	$r3, $r7
	return
ble_else.1953:
	blt	$r8, $r4, ble_else.1954
	beq	$r8, $r4, bne_else.1955
	mov	$r10, $r5
	mov	$r9, $r7
	j	div_binary_search.364
bne_else.1955:
	mov	$r3, $r5
	return
ble_else.1954:
	mov	$r9, $r5
	j	div_binary_search.364

#---------------------------------------------------------------------
# args = [$r4]
# fargs = []
# ret type = Unit
#---------------------------------------------------------------------
print_int.376:
	blt	$r4, $r0, bge_else.1956
	mvhi	$r3, 1525
	mvlo	$r3, 57600
	blt	$r3, $r4, ble_else.1957
	beq	$r3, $r4, bne_else.1959
	addi	$r5, $r0, 0
	j	bne_cont.1960
bne_else.1959:
	addi	$r5, $r0, 1
bne_cont.1960:
	j	ble_cont.1958
ble_else.1957:
	mvhi	$r3, 3051
	mvlo	$r3, 49664
	blt	$r3, $r4, ble_else.1961
	beq	$r3, $r4, bne_else.1963
	addi	$r5, $r0, 1
	j	bne_cont.1964
bne_else.1963:
	addi	$r5, $r0, 2
bne_cont.1964:
	j	ble_cont.1962
ble_else.1961:
	addi	$r5, $r0, 2
ble_cont.1962:
ble_cont.1958:
	mvhi	$r3, 1525
	mvlo	$r3, 57600
	mul	$r3, $r5, $r3
	sub	$r4, $r4, $r3
	blt	$r0, $r5, ble_else.1965
	addi	$r13, $r0, 0
	j	ble_cont.1966
ble_else.1965:
	addi	$r3, $r0, 48
	add	$r3, $r3, $r5
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.1966:
	mvhi	$r6, 152
	mvlo	$r6, 38528
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	mvhi	$r5, 762
	mvlo	$r5, 61568
	sti	$r4, $r1, 0
	blt	$r5, $r4, ble_else.1967
	beq	$r5, $r4, bne_else.1969
	addi	$r9, $r0, 2
	mvhi	$r5, 305
	mvlo	$r5, 11520
	blt	$r5, $r4, ble_else.1971
	beq	$r5, $r4, bne_else.1973
	addi	$r10, $r0, 1
	mvhi	$r5, 152
	mvlo	$r5, 38528
	blt	$r5, $r4, ble_else.1975
	beq	$r5, $r4, bne_else.1977
	mov	$r9, $r12
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.1978
bne_else.1977:
	addi	$r3, $r0, 1
bne_cont.1978:
	j	ble_cont.1976
ble_else.1975:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.1976:
	j	bne_cont.1974
bne_else.1973:
	addi	$r3, $r0, 2
bne_cont.1974:
	j	ble_cont.1972
ble_else.1971:
	addi	$r11, $r0, 3
	mvhi	$r5, 457
	mvlo	$r5, 50048
	blt	$r5, $r4, ble_else.1979
	beq	$r5, $r4, bne_else.1981
	mov	$r10, $r11
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.1982
bne_else.1981:
	addi	$r3, $r0, 3
bne_cont.1982:
	j	ble_cont.1980
ble_else.1979:
	mov	$r9, $r11
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.1980:
ble_cont.1972:
	j	bne_cont.1970
bne_else.1969:
	addi	$r3, $r0, 5
bne_cont.1970:
	j	ble_cont.1968
ble_else.1967:
	addi	$r9, $r0, 7
	mvhi	$r5, 1068
	mvlo	$r5, 7552
	blt	$r5, $r4, ble_else.1983
	beq	$r5, $r4, bne_else.1985
	addi	$r11, $r0, 6
	mvhi	$r5, 915
	mvlo	$r5, 34560
	blt	$r5, $r4, ble_else.1987
	beq	$r5, $r4, bne_else.1989
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.1990
bne_else.1989:
	addi	$r3, $r0, 6
bne_cont.1990:
	j	ble_cont.1988
ble_else.1987:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.1988:
	j	bne_cont.1986
bne_else.1985:
	addi	$r3, $r0, 7
bne_cont.1986:
	j	ble_cont.1984
ble_else.1983:
	addi	$r10, $r0, 8
	mvhi	$r5, 1220
	mvlo	$r5, 46080
	blt	$r5, $r4, ble_else.1991
	beq	$r5, $r4, bne_else.1993
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
	j	bne_cont.1994
bne_else.1993:
	addi	$r3, $r0, 8
bne_cont.1994:
	j	ble_cont.1992
ble_else.1991:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 2
	call	div_binary_search.364
	addi	$r1, $r1, 2
ble_cont.1992:
ble_cont.1984:
ble_cont.1968:
	mvhi	$r5, 152
	mvlo	$r5, 38528
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, 0
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.1995
	beq	$r13, $r0, bne_else.1997
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
	j	bne_cont.1998
bne_else.1997:
	addi	$r14, $r0, 0
bne_cont.1998:
	j	ble_cont.1996
ble_else.1995:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
ble_cont.1996:
	mvhi	$r6, 15
	mvlo	$r6, 16960
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	mvhi	$r5, 76
	mvlo	$r5, 19264
	sti	$r4, $r1, -1
	blt	$r5, $r4, ble_else.1999
	beq	$r5, $r4, bne_else.2001
	addi	$r9, $r0, 2
	mvhi	$r5, 30
	mvlo	$r5, 33920
	blt	$r5, $r4, ble_else.2003
	beq	$r5, $r4, bne_else.2005
	addi	$r10, $r0, 1
	mvhi	$r5, 15
	mvlo	$r5, 16960
	blt	$r5, $r4, ble_else.2007
	beq	$r5, $r4, bne_else.2009
	mov	$r9, $r12
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2010
bne_else.2009:
	addi	$r3, $r0, 1
bne_cont.2010:
	j	ble_cont.2008
ble_else.2007:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2008:
	j	bne_cont.2006
bne_else.2005:
	addi	$r3, $r0, 2
bne_cont.2006:
	j	ble_cont.2004
ble_else.2003:
	addi	$r11, $r0, 3
	mvhi	$r5, 45
	mvlo	$r5, 50880
	blt	$r5, $r4, ble_else.2011
	beq	$r5, $r4, bne_else.2013
	mov	$r10, $r11
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2014
bne_else.2013:
	addi	$r3, $r0, 3
bne_cont.2014:
	j	ble_cont.2012
ble_else.2011:
	mov	$r9, $r11
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2012:
ble_cont.2004:
	j	bne_cont.2002
bne_else.2001:
	addi	$r3, $r0, 5
bne_cont.2002:
	j	ble_cont.2000
ble_else.1999:
	addi	$r9, $r0, 7
	mvhi	$r5, 106
	mvlo	$r5, 53184
	blt	$r5, $r4, ble_else.2015
	beq	$r5, $r4, bne_else.2017
	addi	$r11, $r0, 6
	mvhi	$r5, 91
	mvlo	$r5, 36224
	blt	$r5, $r4, ble_else.2019
	beq	$r5, $r4, bne_else.2021
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2022
bne_else.2021:
	addi	$r3, $r0, 6
bne_cont.2022:
	j	ble_cont.2020
ble_else.2019:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2020:
	j	bne_cont.2018
bne_else.2017:
	addi	$r3, $r0, 7
bne_cont.2018:
	j	ble_cont.2016
ble_else.2015:
	addi	$r10, $r0, 8
	mvhi	$r5, 122
	mvlo	$r5, 4608
	blt	$r5, $r4, ble_else.2023
	beq	$r5, $r4, bne_else.2025
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
	j	bne_cont.2026
bne_else.2025:
	addi	$r3, $r0, 8
bne_cont.2026:
	j	ble_cont.2024
ble_else.2023:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 3
	call	div_binary_search.364
	addi	$r1, $r1, 3
ble_cont.2024:
ble_cont.2016:
ble_cont.2000:
	mvhi	$r5, 15
	mvlo	$r5, 16960
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -1
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2027
	beq	$r14, $r0, bne_else.2029
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.2030
bne_else.2029:
	addi	$r13, $r0, 0
bne_cont.2030:
	j	ble_cont.2028
ble_else.2027:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.2028:
	mvhi	$r6, 1
	mvlo	$r6, 34464
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	mvhi	$r5, 7
	mvlo	$r5, 41248
	sti	$r4, $r1, -2
	blt	$r5, $r4, ble_else.2031
	beq	$r5, $r4, bne_else.2033
	addi	$r9, $r0, 2
	mvhi	$r5, 3
	mvlo	$r5, 3392
	blt	$r5, $r4, ble_else.2035
	beq	$r5, $r4, bne_else.2037
	addi	$r10, $r0, 1
	mvhi	$r5, 1
	mvlo	$r5, 34464
	blt	$r5, $r4, ble_else.2039
	beq	$r5, $r4, bne_else.2041
	mov	$r9, $r12
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2042
bne_else.2041:
	addi	$r3, $r0, 1
bne_cont.2042:
	j	ble_cont.2040
ble_else.2039:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2040:
	j	bne_cont.2038
bne_else.2037:
	addi	$r3, $r0, 2
bne_cont.2038:
	j	ble_cont.2036
ble_else.2035:
	addi	$r11, $r0, 3
	mvhi	$r5, 4
	mvlo	$r5, 37856
	blt	$r5, $r4, ble_else.2043
	beq	$r5, $r4, bne_else.2045
	mov	$r10, $r11
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2046
bne_else.2045:
	addi	$r3, $r0, 3
bne_cont.2046:
	j	ble_cont.2044
ble_else.2043:
	mov	$r9, $r11
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2044:
ble_cont.2036:
	j	bne_cont.2034
bne_else.2033:
	addi	$r3, $r0, 5
bne_cont.2034:
	j	ble_cont.2032
ble_else.2031:
	addi	$r9, $r0, 7
	mvhi	$r5, 10
	mvlo	$r5, 44640
	blt	$r5, $r4, ble_else.2047
	beq	$r5, $r4, bne_else.2049
	addi	$r11, $r0, 6
	mvhi	$r5, 9
	mvlo	$r5, 10176
	blt	$r5, $r4, ble_else.2051
	beq	$r5, $r4, bne_else.2053
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2054
bne_else.2053:
	addi	$r3, $r0, 6
bne_cont.2054:
	j	ble_cont.2052
ble_else.2051:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2052:
	j	bne_cont.2050
bne_else.2049:
	addi	$r3, $r0, 7
bne_cont.2050:
	j	ble_cont.2048
ble_else.2047:
	addi	$r10, $r0, 8
	mvhi	$r5, 12
	mvlo	$r5, 13568
	blt	$r5, $r4, ble_else.2055
	beq	$r5, $r4, bne_else.2057
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
	j	bne_cont.2058
bne_else.2057:
	addi	$r3, $r0, 8
bne_cont.2058:
	j	ble_cont.2056
ble_else.2055:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 4
	call	div_binary_search.364
	addi	$r1, $r1, 4
ble_cont.2056:
ble_cont.2048:
ble_cont.2032:
	mvhi	$r5, 1
	mvlo	$r5, 34464
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -2
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2059
	beq	$r13, $r0, bne_else.2061
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
	j	bne_cont.2062
bne_else.2061:
	addi	$r14, $r0, 0
bne_cont.2062:
	j	ble_cont.2060
ble_else.2059:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
ble_cont.2060:
	addi	$r6, $r0, 10000
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	mvhi	$r5, 0
	mvlo	$r5, 50000
	sti	$r4, $r1, -3
	blt	$r5, $r4, ble_else.2063
	beq	$r5, $r4, bne_else.2065
	addi	$r9, $r0, 2
	addi	$r5, $r0, 20000
	blt	$r5, $r4, ble_else.2067
	beq	$r5, $r4, bne_else.2069
	addi	$r10, $r0, 1
	addi	$r5, $r0, 10000
	blt	$r5, $r4, ble_else.2071
	beq	$r5, $r4, bne_else.2073
	mov	$r9, $r12
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2074
bne_else.2073:
	addi	$r3, $r0, 1
bne_cont.2074:
	j	ble_cont.2072
ble_else.2071:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2072:
	j	bne_cont.2070
bne_else.2069:
	addi	$r3, $r0, 2
bne_cont.2070:
	j	ble_cont.2068
ble_else.2067:
	addi	$r11, $r0, 3
	addi	$r5, $r0, 30000
	blt	$r5, $r4, ble_else.2075
	beq	$r5, $r4, bne_else.2077
	mov	$r10, $r11
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2078
bne_else.2077:
	addi	$r3, $r0, 3
bne_cont.2078:
	j	ble_cont.2076
ble_else.2075:
	mov	$r9, $r11
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2076:
ble_cont.2068:
	j	bne_cont.2066
bne_else.2065:
	addi	$r3, $r0, 5
bne_cont.2066:
	j	ble_cont.2064
ble_else.2063:
	addi	$r9, $r0, 7
	mvhi	$r5, 1
	mvlo	$r5, 4464
	blt	$r5, $r4, ble_else.2079
	beq	$r5, $r4, bne_else.2081
	addi	$r11, $r0, 6
	mvhi	$r5, 0
	mvlo	$r5, 60000
	blt	$r5, $r4, ble_else.2083
	beq	$r5, $r4, bne_else.2085
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2086
bne_else.2085:
	addi	$r3, $r0, 6
bne_cont.2086:
	j	ble_cont.2084
ble_else.2083:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2084:
	j	bne_cont.2082
bne_else.2081:
	addi	$r3, $r0, 7
bne_cont.2082:
	j	ble_cont.2080
ble_else.2079:
	addi	$r10, $r0, 8
	mvhi	$r5, 1
	mvlo	$r5, 14464
	blt	$r5, $r4, ble_else.2087
	beq	$r5, $r4, bne_else.2089
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
	j	bne_cont.2090
bne_else.2089:
	addi	$r3, $r0, 8
bne_cont.2090:
	j	ble_cont.2088
ble_else.2087:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 5
	call	div_binary_search.364
	addi	$r1, $r1, 5
ble_cont.2088:
ble_cont.2080:
ble_cont.2064:
	addi	$r5, $r0, 10000
	mul	$r5, $r3, $r5
	ldi	$r4, $r1, -3
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2091
	beq	$r14, $r0, bne_else.2093
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.2094
bne_else.2093:
	addi	$r13, $r0, 0
bne_cont.2094:
	j	ble_cont.2092
ble_else.2091:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.2092:
	addi	$r6, $r0, 1000
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	addi	$r5, $r0, 5000
	sti	$r4, $r1, -4
	blt	$r5, $r4, ble_else.2095
	beq	$r5, $r4, bne_else.2097
	addi	$r9, $r0, 2
	addi	$r5, $r0, 2000
	blt	$r5, $r4, ble_else.2099
	beq	$r5, $r4, bne_else.2101
	addi	$r10, $r0, 1
	addi	$r5, $r0, 1000
	blt	$r5, $r4, ble_else.2103
	beq	$r5, $r4, bne_else.2105
	mov	$r9, $r12
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2106
bne_else.2105:
	addi	$r3, $r0, 1
bne_cont.2106:
	j	ble_cont.2104
ble_else.2103:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2104:
	j	bne_cont.2102
bne_else.2101:
	addi	$r3, $r0, 2
bne_cont.2102:
	j	ble_cont.2100
ble_else.2099:
	addi	$r11, $r0, 3
	addi	$r5, $r0, 3000
	blt	$r5, $r4, ble_else.2107
	beq	$r5, $r4, bne_else.2109
	mov	$r10, $r11
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2110
bne_else.2109:
	addi	$r3, $r0, 3
bne_cont.2110:
	j	ble_cont.2108
ble_else.2107:
	mov	$r9, $r11
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2108:
ble_cont.2100:
	j	bne_cont.2098
bne_else.2097:
	addi	$r3, $r0, 5
bne_cont.2098:
	j	ble_cont.2096
ble_else.2095:
	addi	$r9, $r0, 7
	addi	$r5, $r0, 7000
	blt	$r5, $r4, ble_else.2111
	beq	$r5, $r4, bne_else.2113
	addi	$r11, $r0, 6
	addi	$r5, $r0, 6000
	blt	$r5, $r4, ble_else.2115
	beq	$r5, $r4, bne_else.2117
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2118
bne_else.2117:
	addi	$r3, $r0, 6
bne_cont.2118:
	j	ble_cont.2116
ble_else.2115:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2116:
	j	bne_cont.2114
bne_else.2113:
	addi	$r3, $r0, 7
bne_cont.2114:
	j	ble_cont.2112
ble_else.2111:
	addi	$r10, $r0, 8
	addi	$r5, $r0, 8000
	blt	$r5, $r4, ble_else.2119
	beq	$r5, $r4, bne_else.2121
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
	j	bne_cont.2122
bne_else.2121:
	addi	$r3, $r0, 8
bne_cont.2122:
	j	ble_cont.2120
ble_else.2119:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 6
	call	div_binary_search.364
	addi	$r1, $r1, 6
ble_cont.2120:
ble_cont.2112:
ble_cont.2096:
	muli	$r5, $r3, 1000
	ldi	$r4, $r1, -4
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2123
	beq	$r13, $r0, bne_else.2125
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
	j	bne_cont.2126
bne_else.2125:
	addi	$r14, $r0, 0
bne_cont.2126:
	j	ble_cont.2124
ble_else.2123:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r14, $r0, 1
ble_cont.2124:
	addi	$r6, $r0, 100
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	addi	$r5, $r0, 500
	sti	$r4, $r1, -5
	blt	$r5, $r4, ble_else.2127
	beq	$r5, $r4, bne_else.2129
	addi	$r9, $r0, 2
	addi	$r5, $r0, 200
	blt	$r5, $r4, ble_else.2131
	beq	$r5, $r4, bne_else.2133
	addi	$r10, $r0, 1
	addi	$r5, $r0, 100
	blt	$r5, $r4, ble_else.2135
	beq	$r5, $r4, bne_else.2137
	mov	$r9, $r12
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2138
bne_else.2137:
	addi	$r3, $r0, 1
bne_cont.2138:
	j	ble_cont.2136
ble_else.2135:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2136:
	j	bne_cont.2134
bne_else.2133:
	addi	$r3, $r0, 2
bne_cont.2134:
	j	ble_cont.2132
ble_else.2131:
	addi	$r11, $r0, 3
	addi	$r5, $r0, 300
	blt	$r5, $r4, ble_else.2139
	beq	$r5, $r4, bne_else.2141
	mov	$r10, $r11
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2142
bne_else.2141:
	addi	$r3, $r0, 3
bne_cont.2142:
	j	ble_cont.2140
ble_else.2139:
	mov	$r9, $r11
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2140:
ble_cont.2132:
	j	bne_cont.2130
bne_else.2129:
	addi	$r3, $r0, 5
bne_cont.2130:
	j	ble_cont.2128
ble_else.2127:
	addi	$r9, $r0, 7
	addi	$r5, $r0, 700
	blt	$r5, $r4, ble_else.2143
	beq	$r5, $r4, bne_else.2145
	addi	$r11, $r0, 6
	addi	$r5, $r0, 600
	blt	$r5, $r4, ble_else.2147
	beq	$r5, $r4, bne_else.2149
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2150
bne_else.2149:
	addi	$r3, $r0, 6
bne_cont.2150:
	j	ble_cont.2148
ble_else.2147:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2148:
	j	bne_cont.2146
bne_else.2145:
	addi	$r3, $r0, 7
bne_cont.2146:
	j	ble_cont.2144
ble_else.2143:
	addi	$r10, $r0, 8
	addi	$r5, $r0, 800
	blt	$r5, $r4, ble_else.2151
	beq	$r5, $r4, bne_else.2153
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
	j	bne_cont.2154
bne_else.2153:
	addi	$r3, $r0, 8
bne_cont.2154:
	j	ble_cont.2152
ble_else.2151:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 7
	call	div_binary_search.364
	addi	$r1, $r1, 7
ble_cont.2152:
ble_cont.2144:
ble_cont.2128:
	muli	$r5, $r3, 100
	ldi	$r4, $r1, -5
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2155
	beq	$r14, $r0, bne_else.2157
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
	j	bne_cont.2158
bne_else.2157:
	addi	$r13, $r0, 0
bne_cont.2158:
	j	ble_cont.2156
ble_else.2155:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r13, $r0, 1
ble_cont.2156:
	addi	$r6, $r0, 10
	addi	$r12, $r0, 0
	addi	$r11, $r0, 10
	addi	$r10, $r0, 5
	addi	$r5, $r0, 50
	sti	$r4, $r1, -6
	blt	$r5, $r4, ble_else.2159
	beq	$r5, $r4, bne_else.2161
	addi	$r9, $r0, 2
	addi	$r5, $r0, 20
	blt	$r5, $r4, ble_else.2163
	beq	$r5, $r4, bne_else.2165
	addi	$r10, $r0, 1
	addi	$r5, $r0, 10
	blt	$r5, $r4, ble_else.2167
	beq	$r5, $r4, bne_else.2169
	mov	$r9, $r12
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2170
bne_else.2169:
	addi	$r3, $r0, 1
bne_cont.2170:
	j	ble_cont.2168
ble_else.2167:
	mov	$r28, $r10
	mov	$r10, $r9
	mov	$r9, $r28
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2168:
	j	bne_cont.2166
bne_else.2165:
	addi	$r3, $r0, 2
bne_cont.2166:
	j	ble_cont.2164
ble_else.2163:
	addi	$r11, $r0, 3
	addi	$r5, $r0, 30
	blt	$r5, $r4, ble_else.2171
	beq	$r5, $r4, bne_else.2173
	mov	$r10, $r11
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2174
bne_else.2173:
	addi	$r3, $r0, 3
bne_cont.2174:
	j	ble_cont.2172
ble_else.2171:
	mov	$r9, $r11
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2172:
ble_cont.2164:
	j	bne_cont.2162
bne_else.2161:
	addi	$r3, $r0, 5
bne_cont.2162:
	j	ble_cont.2160
ble_else.2159:
	addi	$r9, $r0, 7
	addi	$r5, $r0, 70
	blt	$r5, $r4, ble_else.2175
	beq	$r5, $r4, bne_else.2177
	addi	$r11, $r0, 6
	addi	$r5, $r0, 60
	blt	$r5, $r4, ble_else.2179
	beq	$r5, $r4, bne_else.2181
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2182
bne_else.2181:
	addi	$r3, $r0, 6
bne_cont.2182:
	j	ble_cont.2180
ble_else.2179:
	mov	$r10, $r9
	mov	$r9, $r11
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2180:
	j	bne_cont.2178
bne_else.2177:
	addi	$r3, $r0, 7
bne_cont.2178:
	j	ble_cont.2176
ble_else.2175:
	addi	$r10, $r0, 8
	addi	$r5, $r0, 80
	blt	$r5, $r4, ble_else.2183
	beq	$r5, $r4, bne_else.2185
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
	j	bne_cont.2186
bne_else.2185:
	addi	$r3, $r0, 8
bne_cont.2186:
	j	ble_cont.2184
ble_else.2183:
	mov	$r9, $r10
	mov	$r10, $r11
	subi	$r1, $r1, 8
	call	div_binary_search.364
	addi	$r1, $r1, 8
ble_cont.2184:
ble_cont.2176:
ble_cont.2160:
	muli	$r5, $r3, 10
	ldi	$r4, $r1, -6
	sub	$r4, $r4, $r5
	blt	$r0, $r3, ble_else.2187
	beq	$r13, $r0, bne_else.2189
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r5, $r0, 1
	j	bne_cont.2190
bne_else.2189:
	addi	$r5, $r0, 0
bne_cont.2190:
	j	ble_cont.2188
ble_else.2187:
	addi	$r5, $r0, 48
	add	$r3, $r5, $r3
	outputb	$r3
	addi	$r5, $r0, 1
ble_cont.2188:
	addi	$r3, $r0, 48
	add	$r3, $r3, $r4
	outputb	$r3
	return
bge_else.1956:
	addi	$r3, $r0, 45
	outputb	$r3
	sub	$r4, $r0, $r4
	j	print_int.376
