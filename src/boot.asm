bits 16
org 0x7C00

helloworld: db "Hello World!",10,0

mov bp, $
mov si, helloworld
call print_str
jmp bp

print_str:
    mov ah,0x0E ; register prep for bios
    mov bh,0x00
    mov bl,0x07
print:
    mov al, [si] ; get char from pointer
    inc si ; increase pointer

    or al,al ; if end of string 0
    jz return

    int 0x10

    jmp print ; move to next character
return:
    ret

times 510 - ($ - $$) db 0
dw 0xAA55