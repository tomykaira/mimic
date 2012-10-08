#ifndef _COMMON_H
#define _COMMON_H

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#include <vector>
#include <map>
#define rep(i, n) for (int i = 0; i < n; i++)
#define repi(i, n) for (int i = 1; i < n; i++)
#define eq(a, b) (strcmp(a, b) == 0)

#define ROM_NUM (64 * 1024) // 64KByte
#define RAM_NUM (8.00)

#define MAX_INSTS 64 // 6bit

#define INTREG_NUM (32)
#define FLOATREG_NUM (32)


#define ADD     (0x00) // (0b000000)
#define SUB     (0x01) // (0b000001)
#define MUL     (0x02) // (0b000010)
#define AND     (0x03) // (0b000011)
#define OR      (0x04) // (0b000100)
#define NOR     (0x05) // (0b000101)
#define XOR     (0x06) // (0b000110)
#define ADDI    (0x08) // (0b001000)
#define SUBI    (0x09) // (0b001001)
#define MULI    (0x0A) // (0b001010)
#define SLLI    (0x14) // (0b010100)
#define SRAI    (0x15) // (0b010101)
#define ANDI    (0x0B) // (0b001011)
#define ORI     (0x0C) // (0b001100)
#define NORI    (0x0D) // (0b001101)
#define XORI    (0x0E) // (0b001110)
#define FADD    (0x32) // (0b110010)
#define FSUB    (0x33) // (0b110011)
#define FMUL    (0x34) // (0b110100)
#define FMULN   (0x35) // (0b110101)
#define FINV    (0x36) // (0b110110)
#define FSQRT   (0x37) // (0b110111)
#define FMOV    (0x30) // (0b110000)
#define FNEG    (0x31) // (0b110001)
#define IMOVF   (0x16) // (0b010110)
#define FMOVI   (0x17) // (0b010111)
#define MVLO    (0x10) // (0b010000)
#define MVHI    (0x11) // (0b010001)
#define FMVLO   (0x12) // (0b010010)
#define FMVHI   (0x13) // (0b010011)
#define J       (0x38) // (0b111000)
#define BEQ     (0x20) // (0b100000)
#define BLT     (0x21) // (0b100001)
#define BLE     (0x22) // (0b100010)
#define FBEQ    (0x24) // (0b100100)
#define FBLT    (0x25) // (0b100101)
#define FBLE    (0x26) // (0b100110)
#define JR      (0x39) // (0b111001)
#define CALL    (0x3A) // (0b111010)
#define CALLR   (0x3B) // (0b111011)
#define RETURN  (0x3C) // (0b111100)
#define LDR     (0x2C) // (0b101100)
#define FLDR    (0x2E) // (0b101110)
#define STI     (0x29) // (0b101001)
#define LDI     (0x28) // (0b101000)
#define FSTI    (0x2B) // (0b101011)
#define FLDI    (0x2A) // (0b101010)
#define INPUTB  (0x3D) // (0b111101)
#define OUTPUTB (0x3E) // (0b111110)
#define HALT    (0x3F) // (0b111111)
#define DUMP    (0x27) // (0b100111)

using namespace std;
#endif

