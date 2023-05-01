bits 64
jmp err
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
call selectsectorinebx ; read second sector, it should have the first lowkernel block in it

call readsec
call checkerr
; Kernel memory starts from 0x8000. buffer is in 0x00000500
mov rdi, 0x00000500
call readto_rdiaddr



jmp end

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

waitfordrive:
  mov dx, 0x1F7
  mov al, 0
  .loop:
    in al, dx
    test al, 0xC0
  jz .loop
  ret

checkerr:
  mov dx, 0x1F7
  mov al, 0
  in al, dx
  test al, 1
  jz err
  ret
discerrmsg: db "Disk error",0
err:
  xor rax,rax
  mov rdi, 0xB8000
  mov rsi, discerrmsg-1
.loop:
  inc rsi
  mov ah, [rsi]
  or ah,ah
  jz end
  mov byte [rdi], ah
  inc rdi
  mov byte [rdi], 7
  inc rdi
  jmp .loop
end:
  hlt
jmp end