bits 16
org 0x7C00

mov eax, 0x0003 ; clear VGA screen
mov ebx, 0x0000
int 0x10

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

call EnableA20 ; Enable A20 line
lgdt [g_gdt_desc] ; Load GDT

jmp 0:init

init:
  mov ax, 0x10 ; Load the kernel code segment selector
  mov ds, ax ; Load the data segment register
  mov es, ax ; Load the extra segment register
  mov fs, ax ; Load the F segment register
  mov gs, ax ; Load the G segment register
  mov ss, ax ; Load the stack segment register
  jmp 0:0x7E00

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
bits 64

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
  push rax

  ; write control output port
  call A20WaitInput
  mov al, KbdControllerWriteCtrlOutputPort
  out KbdControllerCommandPort, al
  
  call A20WaitInput
  pop rax
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

gdt_:
null_descriptor:
  dd 0
  dd 0

code_kernel_descriptor:
  dw 0xFFFF ; Limit
  dw 0 ; Base
  db 0 ; Base
  db 0x9A ; Access byte
  db 0b11001111 ; Granularity

data_kernel_descriptor:
  dw 0xFFFF ; Limit
  dw 0 ; Base
  db 0 ; Base
  db 0x92 ; Access byte
  db 0b11001111 ; Granularity

code_user_descriptor:
  dw 0xFFFF ; Limit
  dw 0 ; Base
  db 0 ; Base
  db 0xFA ; Access byte
  db 0b11001111 ; Granularity

data_user_descriptor:
  dw 0xFFFF ; Limit
  dw 0 ; Base
  db 0 ; Base
  db 0xF2 ; Access byte
  db 0b11001111 ; Granularity
g_gdt_desc:
  dw g_gdt_desc - gdt_ - 1   ; limit = size of GDT
  dd gdt_                    ; address of GDT

times 510 - ($ - $$) db 0
dw 0xAA55