bits 16
org 0x7C00

bits 64
[SECTION .text64]
MODE64_ENTRY:
    mov ax, 0x18
    mov ds, ax ; Set up data segment
    mov ax, 0x20
    mov ss, ax ; Set up stack segment
    mov rsp, 0x20 ; Set stack pointer
    mov rbp, rsp ; change pointer to 64 bit version

times 510 - ($ - $$) db 0
dw 0xAA55