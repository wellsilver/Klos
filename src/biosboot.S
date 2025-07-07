; bios booting, for debugging with bochs (and also because BIOS is superior to UEFI)

; To boot the kernel, it's ELF just hased to be loaded into writeable memory and started in 64 bit mode (and also its loading point and free mem regions are given)
bits 16
org 0x7C00

jmp start
nop

; This is overwritten by the kfs formatter
db "BAD"
dw 9999
highlighted: dq 9999 ; Overwritten by kfs/format.py

; Remember to preserve EDX (It is set to the boot drive by BIOS)

; 1. Read kernel to memory
; 2. Get memory table
; 3. Get into long mode with kernel mapped correctly 
; 4. jmp to kernel
; in 512 bytes!?!?!?!?? (kfs has room for more but fun challenge if it can fit in 512 bytes)

start:
cli
cld
jmp 0:start2 ; fix bioses going to 0x7c00:0 instead of 0:0x7c00
start2:

mov sp, 0x7C00
mov [0x7c00+1], dl ; save dl

; Reset drive
mov ah, 0
int 13h
mov dl, [0x7c00+1] ; restore dl if it was changed

; Enable disc extensions
mov ah, 0x41
mov bx, 0x55AA
int 13h
mov dl, [0x7c00+1]

mov si, 0
mov ds, si
mov si, discaddr
mov ah, 0x42
int 13h

hlt


; Disc addr packet
discaddr:
db 16 ; size
db 0
.sectnum: dw 1
.ptroff: dw 0x7A00
.ptrseg: dw 0
.lba: dq 1


times 510-($-$$) db 0
dw 0xAA55