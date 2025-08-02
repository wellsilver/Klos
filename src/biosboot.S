; bios booting, for debugging with bochs (and also because BIOS is superior to UEFI)

; To boot the kernel, it's ELF just hased to be loaded into writeable memory and started in 64 bit mode (and also its loading point and free mem regions are given)
bits 16
org 0x7C00

jmp start
nop

; This is overwritten by the kfs formatter
db "BAD"
dw 9999
highlighted: dq 1 ; Overwritten by kfs/format.py

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
mov [0x7C01], dl ; save dl

; Reset drive
mov ah, 0
int 13h
mov dl, [0x7C01] ; restore dl if it was changed

; Read the highlighted sector (which is supposed to be the kernel file)
mov eax, [highlighted]
mov ecx, 1
mov edi, 0x500
call readlba



hlt

; eax = lba
; ecx = ammount of sectors
; edi = to
; converted to int 13h so accuracy is lost idk. uses tempsector and memcopies to edi
; trashes everything

readlba:
  ; eax (lba) to ecx (chs) only cylinder and sector
  xor edx,edx
  mov ecx, 64
  div ecx
  mov cl, dl
  shr eax, 2
  and eax, 0xC0
  mov ch, al
  inc cl

  xor eax, eax
  xor edx, edx
  mov ebx, edi

  mov dl, [0x7C01] ; restore from the saved spot
  mov ah, 2
  mov al, 1

  int 13h
  jc err

  ret

err:
  mov eax, 0xDEADBEEF
  jmp $


times 510-($-$$) db 0
dw 0xAA55