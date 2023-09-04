; bios booting

; file truncated to 3 sectors for kfs
bits 16
org 0x7C00

jmp code
nop

db "kfs"
db 0

code:

cld

; reset vga
mov ah, 00h
mov al, 02h
int 10h

; reset boot disk
xor ah,ah
mov dl, 0x80
int 13h
cmp ah, 0
jnz driveerr

; read the rest of the bootloader
mov ah, 2h
mov al, 2
mov ch, 0 & 0xff
mov cl, 2
mov dh, 0
mov dl, 0x80 ; boot disk
mov es:bx, byte 32256
;mov bx,  ; first byte in mem of next sector
int 13h

; switch to 64 bit mode
mov ax, EC00h
mov bl, 2
int 15h
; ^ amd says to do this



driveerr:
  mov bx, .string - 1
  mov ah, 0xE
.strl:
  inc bx
  mov al, byte [bx]
  cmp byte [bx], 0
  jz .loop
  int 10h
  jmp .strl
.loop:
  hlt
  jmp .loop
.string: db "broken at drive",0

times 510-($-$$) db 0
db 0x55
db 0xAA



times 1024-($-$$) db 0