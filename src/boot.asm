; bios booting

; file truncated to 3 sectors for kfs
bits 16

jmp code
nop

db "kfs"
db 0

code:

