; bios booting

; file truncated to 3 sectors for kfs
bits 16
org 0x7C00

jmp code
nop

db "kfs"
db 0

code:
cld

; reset vga (debug only)
mov ah, 00h
mov al, 02h
int 10h

mov sp, 0x00001000	
mov bp, sp

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

call do_e820
mov word [0x700-3], bp

; switch to 64 bit mode
mov ax, 0xEC00
mov bl, 2
int 15h
; ^ amd says to do this

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
.string: db "check bios",0

times 510-($-$$) db 0
dw 0xAA55
bits 64

; .call. find a type for a kfs folder entry
; rdi=pointertofolder al=typetofind
; returns rdi (pointer to entry in folder) garbage:bl,cl
loopfindtype:
  xor cl, cl
.next:
  mov bl, byte [rdi]
  cmp bl, al
  jz .end
  inc cl
  cmp cl, 16
  jz .endmissing
  add rdi, 32
  jmp .next
.end:
  mov cl,5
  cmp cl , 0 ; clear z flag
  ret
.endmissing:
  mov cl, 5
  cmp cl , 5 ; set z flag
  ret

filename: db "kernel",0,0 ; super conveniently 8 bytes

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
  mov dl, byte [rax]
  mov byte [rbx], dl
  inc rax
  inc rbx
  dec rcx
  cmp rcx, 0
  jnz memcpy
  ret

; 8 bytes from rdi into rax, trashes rcx
stringtorax:
  xor rcx, rcx
.next:
  mov al, byte [rdi]
  shl rax, 8
  inc rdi
  inc rcx
  cmp rcx, 8
  jnz .next
  ret

; 8 bytes from rdi into rbx, trashes rcx,rdx
stringtorbx:
  xor rcx, rcx
.next:
  mov bl, byte [rdi]
  shl rbx, 8
  inc rdi
  inc rcx
  cmp rcx, 8
  jnz .next
  ret

; load kernel
bootloader:
  ; read the / folder into temp
  mov eax, 6
  mov cl, 1
  mov rdi, tempsector
  call ata_lba_read

  ; find data
  mov rdi, tempsector
  mov al, 3
  call loopfindtype
  
  ; pray to god that it worked
  mov rax, 49
  mov rbx, 69
  ; ^ praying to god

  inc rdi
  mov rax, qword [rdi]
  add rdi, 8
  mov rbx, qword [rdi]

  mov rdx, rbx
  sub rdx, rax ; get ammount of sectors to read

  mov cl, 1

  mov rdi, 0x00010000
.readloop:
  call ata_lba_read
  inc rax
  add rdi, 512
  dec rdx
  cmp rdx, 0
  jnz .readloop
  

; jump to kernel
  jmp 0x00010000

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
ata_lba_read:
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
; use the INT 0x15, eax= 0xE820 BIOS function to get a memory map
; note: initially di is 0, be sure to set it to a value so that the BIOS code will not be overwritten. 
;       The consequence of overwriting the BIOS code will lead to problems like getting stuck in `int 0x15`
; inputs: es:di -> destination buffer for 24 byte entries
; outputs: bp = entry count, trashes all registers except esi
mmap_ent equ 0x700             ; the number of entries will be stored at 0x700
do_e820:
  mov di, 0x8004          ; Set di to 0x8004. Otherwise this code will get stuck in `int 0x15` after some entries are fetched 
	xor ebx, ebx		; ebx must be 0 to start
	xor bp, bp		; keep an entry count in bp
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes
	int 0x15
	jc short .failed	; carry set on first call means "unsupported function"
	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
	cmp eax, edx		; on success, eax must have been reset to "SMAP"
	jne short .failed
	test ebx, ebx		; ebx = 0 implies list is only 1 entry long (worthless)
	je short .failed
	jmp short .jmpin
.e820lp:
	mov eax, 0xe820		; eax, ecx get trashed on every int 0x15 call
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes again
	int 0x15
	jc short .e820f		; carry set means "end of list already reached"
	mov edx, 0x0534D4150	; repair potentially trashed register
.jmpin:
	jcxz .skipent		; skip any 0 length entries
	cmp cl, 20		; got a 24 byte ACPI 3.X response?
	jbe short .notext
	test byte [es:di + 20], 1	; if so: is the "ignore this data" bit clear?
	je short .skipent
.notext:
	mov ecx, [es:di + 8]	; get lower uint32_t of memory region length
	or ecx, [es:di + 12]	; "or" it with upper uint32_t to test for zero
	jz .skipent		; if length uint64_t is 0, skip entry
	inc bp			; got a good entry: ++count, move to next storage spot
	add di, 24
.skipent:
	test ebx, ebx		; if ebx resets to 0, list is complete
	jne short .e820lp
.e820f:
	mov [mmap_ent], bp	; store the entry count
	clc			; there is "jc" on end of list to this point, so the carry must be cleared
	ret
.failed:
	stc			; "function unsupported" error exit
	ret
bits 64

db "filenamedump:" ; for ram dump debugging
filenamedump:
  times 28 db 0 ; str
  db 0 ; \0

db "bootloader end |" ; for ram dump debugging

times 2560-($-$$) db 0
tempsector: 
; free until 0x00010000