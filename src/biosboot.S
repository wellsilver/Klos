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

start:
cld
cli

mov ah, 0x41
mov bx, 0x55AA
; DL is kept as the value bios starts it with
int 13h

mov word [lbapkt.bufferoff], 0x7C00-512
mov eax, [highlighted]
mov dword [lbapkt.lba], eax
mov si, 0
mov ds, si
mov si, lbapkt
mov ah, 0x42
; DL is still the boot drive BIOS should have set it to
int 13h

hlt

; Tables

lbapkt:
db 16
db 0
.num: dw 0
.bufferseg: dw 0
.bufferoff: dw 0
.lba: dq 0




times 510-($-$$) db 0
dw 0xAA55