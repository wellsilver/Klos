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

; reset drive
mov ax, 0
mov dl, [0x7c01]
int 13h
jc err

; Read the extra sector
mov eax, 2
mov [diskpacket.lba], eax
mov esi, diskpacket
mov ax, 0x42
mov dl, [0x7c01]
int 13h
jc err

; get e820
; the kernel needs a memory map, need to make it using e820 before long mode (and before unreal mode, since that messes with the registers)
memmap: equ 0x8000

; Only give free memory, kernel/memory/mem.h
; struct memregion {
;  uint64_t base,size;
; } PACKED;

; First write the entire map it gives
xor ebx, ebx ; must be NULL on first call
mov es, bx ; addressing 0x8000
e820loop:
mov eax, 0xE820
mov edi, memmap
mov ecx, 20
mov edx, 0x534D4150
int 15h
jc err

add di, cl ; sometimes it will give more than 20 bytes

; if ebx is 0 (wrapped around and returned to first index) then finish loop
cmp ebx, 0
jne e820loop ; if ready

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

; Read the highlighted sector (should be kernel file)
mov eax, [highlighted]
mov [diskpacket.lba], eax
mov esi, diskpacket
mov ax, 0x4200
mov dl, [0x7c01]
int 13h
jc err

mov eax, [0x500+74] ; starting lba for ELF
mov [diskpacket.lba], eax
mov ecx, [0x500+74+8] ; number of sectors in ELF
mov edi, 0x00100000

; find where the first segment is in the ELF

; get the header
mov esi, diskpacket
mov ax, 0x4200
mov dl, [0x7c01]
int 13h

; get offset to where the segments are stored
mov eax, [0x500+32] ; even though its 64 bits its usually in the first 512 bytes of the header (Get program header offset)
lea ebx, [0x500+eax+8] ; get memory location of offset (get memory location of the segment with the program)
mov eax, [ebx] ; get the offset of the first memory segment (read the memory location)
shr eax, 8 ; divide by 8, div ebx puts garbage in eax for some reason??

add [diskpacket.lba], eax ; add the offset (in sectors) to the program data

; get size of the segment
mov eax, [0x500+32] ; even though its 64 bits its usually in the first 512 bytes of the header (Get program header offset)
lea ebx, [0x500+eax+8+8+8+8] ; get memory location of size
mov eax, [ebx] ; get size (in the file) of segment to eax
mov ebx, 512
div ebx ; divide eax by 512 to get sectors
inc eax ; so we dont lose any straggler bytes in the remainder

mov ecx, eax

mov edi, 0x00100000 ; this is usually free for use.

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
; loop (rep movsb doesnt work)
nextbyte:
mov al, [esi]
mov [edi], al
inc esi
inc edi
loop nextbyte

inc dword [save]
inc dword [diskpacket.lba]

pop ecx
loop nextsector

jmp switchlong

; incase of failure
err:
  mov cx, 12
  lea eax, [rel errstr]
  mov ebx, 0xB8000
  mov sp, 0xdead
errloop:
  mov dl, byte [eax]
  mov byte [ebx], dl
  inc ebx
  mov byte [ebx], 0xF | 1 <<< 7 ; white text | blink
  inc eax
  inc ebx
  loop errloop
  cli
  hlt
  jmp $

errstr: db "KLOS - ERROR"

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

switchlong:

;; create a pagemap to jump to long mode. 
; This is kind of repetitive, there should be a second stage in the kernel to do this from unreal mode...

pagemapl4: equ 0x9000 ; l4 here
pagemapl3: equ 0x9000+0x1000
pagemapl2: equ 0x9000+(0x1000*2)


; map the first 2 pages (in 2 megabyte pages) to real memory, that should be enough space for the kernel to boot
mov eax, pagemapl4
mov ebx, pagemapl3
or ebx, 1 | 2 ; add present and r/w bits
mov dword [eax], ebx ; l4 to l3 (0)

mov eax, pagemapl3 ; pagemapl3[0]
mov ebx, pagemapl2
or ebx, 1 | 2 ; add present and r/w bits
mov dword [eax], ebx

mov eax, pagemapl2
mov ebx, 0 | 1 | 2 | 1<<7; present and r/w and pagesize
mov dword [eax], ebx

; Disable IRQs
mov al, 0xFF                      ; Out 0xFF to 0xA1 and 0x21 to disable all IRQs.
out 0xA1, al
out 0x21, al

nop
nop

lidt [IDT]                        ; Load a zero length IDT so that any NMI causes a triple fault.

; Enter long mode.
mov eax, 10100000b                ; Set the PAE and PGE bit.
mov cr4, eax

mov eax, pagemapl4
mov cr3, eax

mov ecx, 0xC0000080               ; Read from the EFER MSR. 
rdmsr    

or eax, 0x00000100                ; Set the LME bit.
wrmsr
  
mov ebx, cr0                      ; Activate long mode -
or ebx,0x80000001                 ; - by enabling paging and protection simultaneously.
mov cr0, ebx                    

cli
lgdt [GDT.Pointer]                ; Load GDT.Pointer defined below.

jmp 8:LongMode             ; Load CS with 64 bit segment and flush the instruction cache

bits 64
LongMode:

hlt

; Global Descriptor Table
GDT:
.Null:
  dq 0x0000000000000000             ; Null Descriptor - should be present.

.Code:
  dq 0x00209A0000000000             ; 64-bit code descriptor (exec/read).
  dq 0x0000920000000000             ; 64-bit data descriptor (read/write).
    
ALIGN 4
  dw 0                              ; Padding to make the "address of the GDT" field aligned on a 4-byte boundary

.Pointer:
  dw $ - GDT - 1                    ; 16-bit Size (Limit) of GDT.
  dd GDT                            ; 32-bit Base Address of GDT. (CPU will zero extend to 64-bit)


ALIGN 4
IDT:
  .Length       dw 0
  .Base         dd 0

db "Hello there :)"

freearea:
times 1024-($-$$) db 0