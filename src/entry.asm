org 0x7E00
bits 64

call waitready

call reset

mov dx, 0x1F2   ; select the "features" register
mov al, 0x01    ; allow LBA
out dx, al

mov dx, 0x1F7   ; select the "command/status" register
mov al, 0xEF    ; send the "SET FEATURES" command
out dx, al

call waitready
call checkerr

mov r9, 0x00100000 ; used memory
mov rbx, 5 ; first sector with kernel
next:
  call selectsectorinRBX

  call read

  call waitready
  call checkerr
  call waitpoll

  call readtobuf ; read the kfs block to 0x00000500

  call readtomem

  mov rcx, 0x00000500
  mov rax, qword [rcx+11]
  and rax, 0 ; if this is the last kfs block
  jz startkernel ; if its the last kfs block start the kernel

  add rbx, 2
  jmp next

startkernel:
  mov rax, 0xB8000
  mov byte [rax], 'h'
  mov byte [rax+1], 7
.loop:
  hlt
  jmp .loop

selectsectorinRBX:
  ; select master drive
  mov dx, 0x1F6
  xor al, al
  or al, 0xE0 + 0b0000 ; or it with 4 blank bits
  out dx, al

  ; select 2 sectors
  mov dx, 0x1F2
  mov al, 2 ; an entire kfs block (2 sectors)
  out dx, al

  mov dx, 1f2h
  mov eax, ebx        ; Set the LBA low register
  out dx, al

  mov dx, 1f3h
  mov eax, ebx        ; Move ebx into eax
  shr eax, 8          ; Shift eax right by 8 bits to get the LBA mid register
  out dx, al

  mov dx, 1f4h
  mov eax, ebx        ; Move ebx into eax
  shr eax, 16         ; Shift eax right by 16 bits to get the LBA high register
  out dx, al

  ret

readtomem:
  mov esi, 0x00000500+44 ; source, skips the kfs header
  mov rdi, r9 ; destination
  mov ecx, 980
  cld

  rep movsb

  mov r9, rdi ; save rdi
  ret

readtobuf:
  mov dx, 0x1F0          ; set up the DX register with the I/O port number
  mov ecx, 512           ; set up the ECX register with the number of words to read (512 bytes = 256 words) - we are reading 2 sectors
  mov edi, 0x00000500        ; set up the EDI register with the address of the buffer
  cld                    ; ensure that the direction flag is cleared

  rep insw               ; perform a repeated string input operation from the I/O port into memory

  ret

reset:
  mov dx, 0x1F0
  mov al, 4
  out dx, al
  xor eax, eax
  out dx, al
  in al, dx
  in al, dx
  in al, dx
  in al, dx
  ret

read:
  mov dx, 0x1F7
  mov al, 0x20 ; read with retry
  out dx, al
  ret

waitpoll:
  mov dx, 0x1F7
.loop:
  xor al,al
  in al, dx
  test al, 1 << 3
  jz .loop
  mov rax, 0xB8000
  mov byte [rax], ' '
  mov byte [rax+1], 7
  ret

waitready:
  mov rax, 0xB8000
  mov byte [rax], '*'
  mov byte [rax+1], 7
  xor al, al
  mov dx, 0x1F7
.loop:
    in al, dx
    test al, 1 << 6 ; if ready
    jz .loop
  ret

checkerr:
  mov dx, 0x1F7
  mov al, 0
  in al, dx
  test al, 1 << 0
  jz err
  test al, 1 << 5
  jz err
  ret
err:
  mov rax, 0xb8000
  xor rcx,rcx
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