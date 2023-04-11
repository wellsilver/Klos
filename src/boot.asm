bits 16
org 0x7C00

; Initialize disk
mov dl, 0x80 ; Select disk 0 (change this to the appropriate disk number)
mov ah, 0x00 ; int13h function 0
int 0x13     ; Reset disk

; Read sector
mov ax, 0x0000 ; Read mode, use CHS addressing
mov es, ax     ; Segment for buffer
mov bx, 0x7E00 ; Offset for buffer
mov ah, 0x02   ; int13h function 2
mov al, 0x01   ; Number of sectors to read
mov ch, 0x00   ; Cylinder number
mov cl, 0x02   ; Sector number
mov dh, 0x00   ; Head number
int 0x13       ; Read sector

jz brokendisc    ; jump to error label if carry flag is set (error occurred)

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
  mov rsp, 0x00007BFF
  mov rbp, rsp
  jmp 0x7E00+64 ; jump to the memory where our kernel is.

bits 16
brokenmsg: db "Disk Error",0
brokendisc: ; if disk read fails
  mov ah, 0Eh
  mov si, brokenmsg-1
brokenchr:
  inc si
  mov al, [si]
  or al, al
  jz brokenloop
  int 0x10
  jmp brokenchr
brokenloop: jmp brokenloop

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

times 510 - ($ - $$) db 0
dw 0xAA55