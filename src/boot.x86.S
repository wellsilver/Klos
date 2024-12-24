; bios booting

; file truncated to 3 sectors for kfs
bits 16
org 0x7C00

jmp code
nop

db "KFS"
dw 2 ; version
highlighted: dq 12 ; kernel is at 12 I hope lol

code:
cld

mov eax, 0xB8000
mov word [eax],   0x0762
add eax, 2
mov word [eax], 0x076f
add eax, 2
mov word [eax], 0x076F
add eax, 2
mov word [eax], 0x0774

xor ax, ax 
mov ss, ax     ; setup stack
mov sp, 0x7b0f-2 ; stack grows downwards from 0x7C00

; reset boot disk
xor ah,ah
mov dl, 0x80
int 13h
cmp ah, 0
jnz err

; read the rest of the bootloader
mov ah, 2h
mov al, 2
mov ch, 0 & 0xff
mov cl, 2
mov dh, 0
mov dl, 0x80 ; boot disk
mov bx, 32256
;mov bx,  ; first byte in mem of next sector
int 13h

jmp do_e820
frome820:


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
  mov rsp, 0x00000500
  mov rbp, rsp

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

type: db 0

times 510-($-$$) db 0
dw 0xAA55
bits 64

; .call. find a type for a kfs folder entry
; rdi=pointertofolder al=typetofind
; returns rdi (pointer to entry in folder) garbage:bl,cl
loopdirfindtype:
  xor cl, cl
.next:
  mov bl, byte [rdi]
  cmp bl, al
  jz .end
  inc cl
  cmp cl, 20
  jz .endmissing
  add rdi, 25
  jmp .next
.end:
  mov cl,5
  cmp cl , 0 ; clear z flag
  ret
.endmissing:
  mov cl, 5
  cmp cl , 5 ; set z flag
  ret

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

; memory copy.
; rax = from, rbx = to, rcx = how many bytes to transfer. garbage rdx
memcpy:
  mov dx, word [rax]
  mov word [rbx], dx
  inc rax
  inc rbx
  dec rcx
  cmp rcx, 0
  jnz memcpy
  ret

bootloader:
  ; get the describing sector
  mov rax, qword [highlighted]
  mov rcx, 1
  mov rdi, tempsector
  call ata_lba_read

  ; get ELF header size
  mov rax, qword [tempsector+74] ; start LBA
  mov r8, rax ; save the start LBA
  mov rcx, 1
  mov rdi, tempsector
  call ata_lba_read

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
  call ata_lba_read

  ; memory for kernel
  mov rbp, 0x0007FFFF
  mov rsp, 0x0007FFFF

  jmp 0x100000

haltloop:
  hlt
  jmp haltloop

; from osdev
;=============================================================================
; ATA read sectors (LBA mode) 
;
; @param EAX Logical Block Address of sector
; @param CL  Number of sectors to read
; @param RDI The address of buffer to put data obtained from disk
;
; @return None
;=============================================================================
ata_lba_read: ; replace with a fallback to real mode so it works with every drive the bios supports
  pushfq
  and rax, 0x0FFFFFFF
  push rax
  push rbx
  push rcx
  push rdx
  push rdi

  mov rbx, rax         ; Save LBA in RBX

  mov edx, 0x01F6      ; Port to send drive and bit 24 - 27 of LBA
  shr eax, 24          ; Get bit 24 - 27 in al
  or al, 11100000b     ; Set bit 6 in al for LBA mode
  out dx, al

  mov edx, 0x01F2      ; Port to send number of sectors
  mov al, cl           ; Get number of sectors from CL
  out dx, al

  mov edx, 0x1F3       ; Port to send bit 0 - 7 of LBA
  mov eax, ebx         ; Get LBA from EBX
  out dx, al

  mov edx, 0x1F4       ; Port to send bit 8 - 15 of LBA
  mov eax, ebx         ; Get LBA from EBX
  shr eax, 8           ; Get bit 8 - 15 in AL
  out dx, al


  mov edx, 0x1F5       ; Port to send bit 16 - 23 of LBA
  mov eax, ebx         ; Get LBA from EBX
  shr eax, 16          ; Get bit 16 - 23 in AL
  out dx, al

  mov edx, 0x1F7       ; Command port
  mov al, 0x20         ; Read with retry.
  out dx, al

.still_going:  in al, dx
  test al, 8           ; the sector buffer requires servicing.
  jz .still_going      ; until the sector buffer is ready.

  mov rax, 256         ; to read 256 words = 1 sector
  xor bx, bx
  mov bl, cl           ; read CL sectors
  mul bx
  mov rcx, rax         ; RCX is counter for INSW
  mov rdx, 0x1F0       ; Data port, in and out
  rep insw             ; in to [RDI]

  pop rdi
  pop rdx
  pop rcx
  pop rbx
  pop rax
  popfq
  ret

bits 16

do_e820:
  ; make a page table (growing down from 0x00EFFFFF)
  ; for long mode!!
  


.end:
  jmp frome820
bits 64

db "boot code end |" ; for ram dump debugging

times 2560-($-$$) db 1

tempsector: 
; free until 0xFF00
;            0x7C00