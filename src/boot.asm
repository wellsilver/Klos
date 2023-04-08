bits 16
org 0x7C00

mov ah,1
jmp start

EnableA20:
    ; disable keyboard
    call A20WaitInput
    mov al, KbdControllerDisableKeyboard
    out KbdControllerCommandPort, al

    ; read control output port
    call A20WaitInput
    mov al, KbdControllerReadCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitOutput
    in al, KbdControllerDataPort
    push eax

    ; write control output port
    call A20WaitInput
    mov al, KbdControllerWriteCtrlOutputPort
    out KbdControllerCommandPort, al
    
    call A20WaitInput
    pop eax
    or al, 2                                    ; bit 2 = A20 bit
    out KbdControllerDataPort, al

    ; enable keyboard
    call A20WaitInput
    mov al, KbdControllerEnableKeyboard
    out KbdControllerCommandPort, al

    call A20WaitInput
    ret

A20WaitInput:
    ; wait until status bit 2 (input buffer) is 0
    ; by reading from command port, we read status byte
    in al, KbdControllerCommandPort
    test al, 2
    jnz A20WaitInput
    ret

A20WaitOutput:
    ; wait until status bit 1 (output buffer) is 1 so it can be read
    in al, KbdControllerCommandPort
    test al, 1
    jz A20WaitOutput
    ret

KbdControllerDataPort               equ 0x60
KbdControllerCommandPort            equ 0x64
KbdControllerDisableKeyboard        equ 0xAD
KbdControllerEnableKeyboard         equ 0xAE
KbdControllerReadCtrlOutputPort     equ 0xD0
KbdControllerWriteCtrlOutputPort    equ 0xD1

start:
; read second sector, where our system driver should be
mov ah, 2h    ; int13h function 2
mov al, 1     ; we want to read 1 sector
mov ch, 0     ; from cylinder number 0
mov cl, 2     ; the sector number 2 - second sector (starts from 1, not 0)
mov dh, 0     ; head number 0
xor bx, bx    
mov es, bx    ; es should be 0
mov bx, 7e00h ; 512bytes from origin address 7c00h
int 13h

mov eax, 0x0003 ; setup VGA
mov ebx, 0x0000
int 0x10

mov ax, 0x18
mov ds, ax
mov ax, 0x20
mov ss, ax
bits 64 ; switch to 64 bits
mov rsp, 0x20
mov rbp, rsp

; switch to protected mode
cli
call EnableA20
lgdt [g_gdt_desc]
mov rax, cr0
or rax, 1
mov cr0, rax

mov rax, 7300h
jmp rax

g_GDT:      ; NULL descriptor
    dq 0

    ; 64-bit code segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
    db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 64-bit data segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
    db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 32-bit code segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
    db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 32-bit data segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
    db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 16-bit code segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
    db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
    db 0                        ; base high

    ; 16-bit data segment
    dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
    dw 0                        ; base (bits 0-15) = 0x0
    db 0                        ; base (bits 16-23)
    db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
    db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
    db 0                        ; base high
g_gdt_desc:
    dw g_gdt_desc - g_GDT - 1   ; limit = size of GDT
    dd g_GDT                    ; address of GDT

times 510 - ($ - $$) db 0
dw 0xAA55