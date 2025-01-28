; bios booting

; file truncated to 3 sectors for kfs
bits 16
org 0x7C00

jmp code
nop

db "KFS"
dw 2 ; version
highlighted: dq 12 ; kernel is at 12 I hope lol
; ^ it is at 12 but this is reset by the disc formater

discsave: db 0

code:
cld

mov byte [discsave], dl

mov eax, 0xB8000
mov word [eax], 0x0762
add eax, 2
mov word [eax], 0x076f
add eax, 2
mov word [eax], 0x076F
add eax, 2
mov word [eax], 0x0774

; clear segment registers
; freezes wtf???
xor ax, ax
;mov cs, ax
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

mov sp, 0x7C00 ; stack grows downwards from 0x7C00

; reset boot disk
xor ah,ah
mov dl, byte [discsave]
int 13h
cmp ah, 0
jnz err

; load the rest of the bootloader
mov eax, 1
mov ecx, 4
mov edi, 0x7E00
call readlba

call do_e820

hltloop: hlt
jmp hltloop

bits 16
err:
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
.string: db "Unsupported",0
; ^ more playful message?

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
  mov ebx, 500h

  mov dl, byte [discsave]
  mov ah, 2
  mov al, 1

  int 13h
  jc err

  ret

e820sizestore: dq 0
; write e820 to memory so when we get to 64 bit mode can make a full one
do_e820:
  mov edi, tempsector
	xor ebx, ebx		; ebx must be 0 to start
	xor bp, bp		; keep an entry count in bp
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820
	mov ecx, 24		; ask for 24 bytes
	int 0x15
	jc err

  xor bp, bp
.loopu:
  mov eax, 0xe820		; eax, ecx get trashed on every int 0x15 call
	mov ecx, 24		; ask for 24 bytes again
  int 0x15
  inc bp
  add di, 24
  jc .end
  jmp .loopu

.end:
  mov ax, bp
  mov word [e820sizestore], ax
  ret

times 510-($-$$) db 1
dw 0xAA55

bits 16
switch32:
cli
lgdt [GDT32.GDT_descriptor]
in al, 0x92
or al, 2
out 0x92, al
mov eax, cr0
or eax, 1
mov cr0, eax
jmp CODE_SEG:protected32

bits 32
protected32: ; switch straight to long mode
  mov edi, 0x1000              ; Set the destination index to 0x1000.
  mov cr3, edi                 ; Set control register 3 to the destination index.
  xor eax, eax                 ; Nullify the A-register.
  mov ecx, 4096                ; Set the C-register to 4096.
  rep stosd                    ; Clear the memory.
  mov edi, cr3                 ; Set the destination index to control register 3.
  mov DWORD [edi], 0x2003      ; Set the uint32_t at the destination index to 0x2003.
  add edi, 0x1000              ; Add 0x1000 to the destination index.
  mov DWORD [edi], 0x3003      ; Set the uint32_t at the destination index to 0x3003.
  add edi, 0x1000              ; Add 0x1000 to the destination index.
  mov DWORD [edi], 0x4003      ; Set the uint32_t at the destination index to 0x4003.
  add edi, 0x1000              ; Add 0x1000 to the destination index.
  mov ebx, 0x00000003          ; Set the B-register to 0x00000003.
  mov ecx, 512                 ; Set the C-register to 512.
.SetEntry:
    mov DWORD [edi], ebx         ; Set the uint32_t at the destination index to the B-register.
    add ebx, 0x1000              ; Add 0x1000 to the B-register.
    add edi, 8                   ; Add eight to the destination index.
    loop .SetEntry               ; Set the next entry.
.next:
    mov eax, cr4                 ; Set the A-register to control register 4.
    or eax, 1 << 5               ; Set the PAE-bit, which is the 6th bit (bit 5).
    mov cr4, eax                 ; Set control register 4 to the A-register.
    mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
    rdmsr                        ; Read from the model-specific register.
    or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
    wrmsr                        ; Write to the model-specific register.
    mov eax, cr0                 ; Set the A-register to control register 0.
    or eax, 1 << 31              ; Set the PG-bit, which is the 32nd bit (bit 31).
    mov cr0, eax                 ; Set control register 0 to the A-register.
    lgdt [GDT64.Pointer]         ; Load the 64-bit global descriptor table.
    jmp GDT64.Code:longmode      ; Set the code segment and enter 64-bit long mode.


bits 64
longmode:
  cli                           ; Clear the interrupt flag.
  mov ax, GDT64.Data            ; Set the A-register to the data descriptor.
  mov ds, ax                    ; Set the data segment to the A-register.
  mov es, ax                    ; Set the extra segment to the A-register.
  mov fs, ax                    ; Set the F-segment to the A-register.
  mov gs, ax                    ; Set the G-segment to the A-register.
  mov ss, ax                    ; Set the stack segment to the A-register.

  jmp bootloader

GDT32:                          ; must be at the end of real mode code
.GDT_null:
  dd 0x0
  dd 0x0
.GDT_code:
  dw 0xffff
  dw 0x0
  db 0x0
  db 0b10011010
  db 0b11001111
  db 0x0
.GDT_data:
  dw 0xffff
  dw 0x0
  db 0x0
  db 0b10010010
  db 0b11001111
  db 0x0
.GDT_descriptor:
  dw GDT32.GDT_descriptor - GDT32 - 1
  dd GDT32

CODE_SEG equ GDT32.GDT_code - GDT32
DATA_SEG equ GDT32.GDT_data - GDT32

; Access bits
PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0
 
; Flags bits
GRAN_4K       equ 1 << 7
SZ_32         equ 1 << 6
LONG_MODE     equ 1 << 5
 
GDT64: ; 64 bit gdt
  .Null: equ $ - GDT64
    dq 0
  .Code: equ $ - GDT64
    dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
    db 0                                        ; Base (mid, bits 16-23)
    db PRESENT | NOT_SYS | EXEC | RW            ; Access
    db GRAN_4K | LONG_MODE | 0xF                ; Flags & Limit (high, bits 16-19)
    db 0                                        ; Base (high, bits 24-31)
  .Data: equ $ - GDT64
    dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
    db 0                                        ; Base (mid, bits 16-23)
    db PRESENT | NOT_SYS | RW                   ; Access
    db GRAN_4K | SZ_32 | 0xF                    ; Flags & Limit (high, bits 16-19)
    db 0                                        ; Base (high, bits 24-31)
  .TSS: equ $ - GDT64
    dd 0x00000068
    dd 0x00CF8900
  .Pointer:
    dw $ - GDT64 - 1
    dq GDT64

; print str vga, for debug only. garbage=rax,rbx rdi=pointertostring. string is null terminated
prints:
  mov rax, 0xb8000
  xor rbx, rbx
  dec rdi
.loop:
  inc rdi
  mov ch, byte [rdi]
  mov byte [rax], ch
  inc rax
  mov byte [rax], 7
  inc rax
  cmp ch, 0
  jnz .loop
  ret

loadstr: db "load",0
runnstr: db "run",0

settuppaging:
  mov rdi, tempsector
  sub rdi, 24 ; so we can add 24 immediately and be fine

  mov rax, qword [e820sizestore]
  mov cl, 24
  mul cl
  add rax, tempsector
  mov r12, rax

  ; search for the largest spot in memory put begin=r10 size=r11
  mov r10, 0
  mov r11, 0
.searchlargest:
  add rdi, 24
  ; skip this entry if it is not free
  cmp dword [rdi+16], 1
  jne .searchlargest
  ; check if we ran out of entries to search
  cmp r12, rdi
  jng .endsearchlargest
  ; check if this entry is bigger than the previous largest entry, if it is record it
  cmp qword [rdi+8], r11
  jng .searchlargest
  mov r10, qword [rdi]
  mov r11, qword [rdi+8]
  jmp .searchlargest
.endsearchlargest:

  mov rax, r10
  add rax, r11

  ret

loadkernel:
  ; get the describing sector
  mov rax, qword [highlighted]
  mov rcx, 1
  mov rdi, tempsector
  call 0

  ; get ELF header size
  mov rax, qword [tempsector+74] ; start LBA
  mov r8, rax ; save the start LBA
  mov rcx, 1
  mov rdi, tempsector
  call 0

  mov rax, qword [rdi+32]
  add rdi, rax

  mov r9, qword [rdi+8] ; offset in the file
  mov r10, qword [rdi+32] ; size

  ; get the offset (in sectors)
  mov rax, r9
  mov rbx, 512
  div rbx
  mov r12, rax ; offset in sectors

  ; get the size in sectors
  mov rax, r10
  mov rbx, 512
  div rbx
  mov r13, rax ; size in sectors
  inc r13

  mov rax, r12
  add rax, r8
  mov rcx, r13
  mov rdi, 0x100000
  call 0

  ret

bootloader:
  mov rdi, loadstr
  call prints

  call settuppaging
  
  mov rdi, runnstr
  call prints


haltloop:
  hlt
  jmp haltloop

db "boot code end |" ; for ram dump debugging

times 2560-($-$$) db 1

tempsector: 
; free until 0xFF00
;            0x7C00