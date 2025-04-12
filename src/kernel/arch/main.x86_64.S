; this is linked with main.c for compability with random shit, no relation to ../boot.asm
; also include other asm files from here, so we dont need to compile everything separately


; gdt sorting and everything else here
section .asm
global entry
extern kernel
extern stackend

; kernel should be capable of fully loading itself with just the entry point, memory map and kernel in memory
; setup before kernel. This is just undoing all the uefi (or other bootloader) set stuff before actually entering kernel
; Do not touch rdi, rsi, rdx (they contain Sysv function parameters for kernel)
entry:
  ; stack setup, space is reserved by the linker script
  mov rsp, stackend
  dec rsp

  ; ensure cache is enabled, write protect enabled
  mov rax, cr0
  or rax, 1 << 16 ; enable write protect
  and rax, ~(1 << 30) ; zero cache disable bit (if cr0.cd is zero then cache is enabled)
  mov cr0, rax

  ; new IDT
  mov rax, rdi
  add rax, idtptr - 0x100000
  lidt [rax]

  ; new GDT
  mov rax, rdi
  add rax, gdtptr - 0x100000
  lgdt [rax]

  ; setup a new page map

  ; flush cache writes for coproccessors (is this a good idea?)
  wbnoinvd

  jmp kernel

entryend:

idtptr:
  dw (idt64.end - idt64) - 1
  dq idt64

idt64:
  times 256 dq 0
.end:

gdtptr:
  dw (gdt64.end - gdt64) - 1
  dq gdt64

gdt64:
  times 16 dq 0
.end: