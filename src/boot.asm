; bios booting
bits 16

jmp code
nop

dq "MSWIN4.1"
dw 512
db 2


code: