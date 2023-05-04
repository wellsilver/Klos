bits 64
org 0x7E00

mov dx, 0x1F6
mov ah, 0b00100000
out dx, al          ; LBA setup

call waitfordrive

mov dx, 0x1F0       ; Set the data port address
mov al, 0xA1        ; Set the command byte (0xA1 is the command code for IDENTIFY PACKET DEVICE)
out dx, al          ; Send the command byte to the ATAPI device

call waitfordrive

mov dx, 0x1F0 ; Set the data port address
mov cx, 256   ; Set the count of words to be read (512 bytes / 2 = 256 words)
mov rdi, 0x00000500 ; some free memory below our stack, we can forget about this later
cld           ; Set the direction flag to forward (incrementing)
rep insw      ; Read the data from the data register into memory

mov dx, 0x1F2   ; select the "features" register
mov al, 0x05    ; allow APM
out dx, al

mov dx, 0x1F7   ; select the "command/status" register
mov al, 0xEF    ; send the "SET FEATURES" command
out dx, al

call waitfordrive

mov dx, 0x1F2   ; select the "features" register
mov al, 0x01    ; allow LBA
out dx, al

mov dx, 0x1F7   ; select the "command/status" register
mov al, 0xEF    ; send the "SET FEATURES" command
out dx, al

call waitfordrive

mov ebx, 2
mov rdi, 0x00100000
next:
call selectsectorinebx ; read second sector, it should have the first lowkernel block in it

call readsec

call waitfordrive

call checkerr

; Kernel memory starts from 0x00100000. buffer is in 0x00000500
mov rsi, 0x00000500

mov r9, rdi
mov rdi, 0x00000500
call readto_rdiaddr
mov rdi, r9
mov ah, byte [rsi+11] ; get the "next ptr" pointer

add rsi, 44
;esi ; Source address
;edi ; Destination address
mov ecx, 980 ; Number of bytes to copy
rep movsb ; Copy data
add rdi, 980

cmp ah, 0
jz startkernel ; if the "next ptr" pointer is 0, start the kernel

; read next sector if there is more kernel to load
inc ebx
jmp next

startkernel: ; setup for kernel
mov rax, qword [0x00100000+12] ; get the position of entry function
add rax, 0x00100000
jmp rax

selectsectorinebx:
  mov eax, ebx        ; Set the LBA low register
  out dx, al

  mov eax, ebx        ; Move ebx into eax
  shr eax, 8          ; Shift eax right by 8 bits to get the LBA mid register
  out dx, al

  mov eax, ebx        ; Move ebx into eax
  shr eax, 16         ; Shift eax right by 16 bits to get the LBA high register
  out dx, al
  ret

readto_rdiaddr:
  mov dx, 0x1F0 ; Set the data port address
  mov cx, 256   ; Set the count of words to be read (512 bytes / 2 = 256 words)
  cld           ; Set the direction flag to forward (incrementing)
  rep insw      ; Read the data from the data register into memory
  ret

readsec:
  mov dx, 0x1F7
  mov al, 0x20 ; READ SECTORS
  out dx, al
  ret

;.still_going:  in al, dx;
;    test al, 8           ; the sector buffer requires servicing.
;    jz .still_going      ; until the sector buffer is ready.
waitfordrive:
  mov dx, 0x1F0
  mov al, 0
  .loop:
    in al, dx
    test al, 0x40
    jz .loop
  ret

checkerr:
  mov dx, 0x1F7
  mov al, 0
  in al, dx
  test al, 1
  jz err
  ret
err:
  mov rax, 0xb8000
  mov rdi, discerrmsg-1
.loop:
  inc rdi
  mov ch, [rdi]
  mov byte [rax], ch
  inc rax
  mov byte [rax], 7
  inc rax
  and ch, 0
  jz .loop
end:
  hlt
jmp end

discerrmsg: db "Disc error",0 ; for "err" function