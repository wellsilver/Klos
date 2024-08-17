; this is linked with main.c for compability with random shit, no relation to ../boot.asm
; also include other asm files from here, so we dont need to compile everything separately
section .text
extern kernel
global start

start:
  jmp kernel