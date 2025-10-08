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

; Enter unreal mode so we can load the kernel into upper free memory
unrealmode:
xor ax, ax
mov ds, ax

cli                    ; no interrupts
push ds                ; save real mode

lgdt [gdt32info]         ; load gdt register

mov  eax, cr0          ; switch to pmode by
or al,1                ; set pmode bit
mov  cr0, eax
jmp 0x8:.pmode

.pmode:
  mov  bx, 0x10          ; select descriptor 2
  mov  ds, bx            ; 10h = 10000b

  and al,0xFE            ; back to realmode
  mov  cr0, eax          ; by toggling bit again
  jmp 0x0:.unreal

.unreal:
  pop ds                 ; get back old segment

  mov bx, 0x0f01         ; attrib/char of smiley :)
  mov eax, 0x0b8000      ; note 32 bit offset
  mov word [ds:eax], bx

mov ax, 0
mov dl, [0x7c01]
int 13h

; Read the highlighted sector (which is supposed to be the kernel file)
mov eax, [highlighted]
mov ecx, 1
mov edi, 0x500
call readlba

mov eax, [0x500+74] ; start LBA
mov ecx, [0x500+74+8] ; sectors to read
mov edi, 0x500 ; extended memory
call readlba

hlt

; eax = lba
; ecx = ammount of sectors
; edi = to
; converted to int 13h so accuracy is lost idk. uses tempsector and memcopies to edi
; trashes everything

readlba:
  ; eax (lba) to ecx (chs) only cylinder and sector
  push eax
  push ecx
  push edi
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
  jc retry

  pop edi ; restore the original arguments
  pop ecx
  pop eax

  add edi, 512 ; next sector
  dec ecx ; dont read this sector twice (finished this sector)
  inc eax ; next sector to read (finished this sector)

  cmp ecx, 0 ; check if the read sector was the last sector
  jg readlba

  ret

; Kept getting 0x0c error when trying to read (and looking through seabios, that is the only error other than write protect error that gets used...)
; and it was caused by the atapio hardware saying it error'd even though it shouldnt have an error?
retry:
  mov ax, 0
  mov dl, [0x7c01]
  int 13h

  pop edi
  pop ecx
  pop eax

  jmp readlba


gdt32info:
  dw gdt_end - gdt32 - 1   ;last byte in table
  dd gdt32                 ;start of table

gdt32:        dd 0,0        ; entry 0 is always unused
codedesc:   db 0xff, 0xff, 0, 0, 0, 10011010b, 00000000b, 0
flatdesc:   db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
gdt_end:

times 510-($-$$) db 0
dw 0xAA55