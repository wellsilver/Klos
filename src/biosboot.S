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
mov es, ax
cli                    ; no interrupts
push es ; save real mode
push ds

lgdt [gdt32info]         ; load gdt register

mov eax, cr0          ; switch to pmode by
or al,1                ; set pmode bit
mov cr0, eax
jmp 0x8:.pmode

.pmode:
  mov bx, 0x10          ; select descriptor 2
  mov ds, bx            ; 10h = 10000b
  mov es, bx

  and al,0xFE            ; back to realmode
  mov  cr0, eax          ; by toggling bit again
  jmp 0x0:.unreal

.unreal:
  pop ds                 ; get back old segment
  pop es
  
  mov bx, 0x0f01         ; attrib/char of smiley :)
  mov eax, 0x0b8000      ; note 32 bit offset
  mov word [ds:eax], bx

mov ah, 0x41
mov bx, 0x55aa
mov dl, [0x7c01]
int 13h
jc err

mov ax, 0
mov dl, [0x7c01]
int 13h
jc err

; Read the highlighted sector (should be kernel file)
mov eax, [highlighted]
mov [diskpacket.lba], eax
mov esi, diskpacket
mov ax, 0x4200
mov dl, [0x7c01]
int 13h
jc err

mov eax, [0x500+74] ; starting lba
mov [diskpacket.lba], eax
mov ecx, [0x500+74+8] ; number of sectors
mov edi, 0x00100000

; get each sector individually then rep movsb them to upper memory
nextsector:
push ecx
push edi

; read the next sector to the cache
mov esi, diskpacket
mov ax, 0x4200
mov dl, [0x7c01]
int 13h
jc err

; 512 bytes from the cache to upper memory
mov ecx, 512
mov esi, 0x500
pop edi
;rep movsb

mov eax, save
inc dword [eax]

pop ecx
loop nextsector

hlt

err:
  mov esp, 0xdeadbeef
  jmp $

save: dd 0

diskpacket:
db 10h
db 0
.sectors: dw 1
.tooffset: dw 0x500
.tosegment: dw 0
.lba: dq 0

gdt32info:
  dw gdt_end - gdt32 - 1   ;last byte in table
  dd gdt32                 ;start of table

gdt32:        dd 0,0        ; entry 0 is always unused
codedesc:   db 0xff, 0xff, 0, 0, 0, 10011010b, 00000000b, 0
flatdesc:   db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
gdt_end:

times 510-($-$$) db 0
dw 0xAA55