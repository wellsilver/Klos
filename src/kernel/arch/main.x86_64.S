; this is linked with main.c for compability with random shit, no relation to ../boot.asm
; also include other asm files from here, so we dont need to compile everything separately


; gdt sorting and everything else here
section .asm
global entry
extern kernel
extern stackend
extern pagemap

; kernel should be capable of fully loading itself with just the entry point, memory map and kernel in memory
; setup before kernel. This is just undoing all the uefi (or other bootloader) set stuff before actually entering kernel
; Do not touch rdi, rsi, rdx, r8 (they contain Sysv function parameters for kernel)
entry:
  ; stack setup, space is reserved by the linker script
  mov rsp, stackend
  dec rsp

  ; ensure cache is enabled, write protect enabled
  mov rax, cr0
  or rax, 1 << 16 ; enable write protect
  and rax, ~(1 << 30) ; zero cache disable bit (if cr0.cd is zero then cache is enabled)
  mov cr0, rax

  ; if not working after being loaded to virtual memory, it is because idtptr and gdtptr are not adjusted
  ; new IDT
  mov rax, rdi
  add rax, idtptr-0x1000
  lidt [rax]

  ; new GDT
  mov rax, rdi
  add rax, gdtptr-0x1000
  lgdt [rax]
  
  ; create a new page map
  call newcr3

  ; flush cache writes for coproccessors (is this a good idea?)
  wbnoinvd

  jmp kernel

entryend:

newcr3:
  ; get addr
  mov rbx, rdi
  add rbx. pagemap-0x1000

  call cr3pageclear

  

  ret

cr3pageclear:
  mov rax, 0
  mov rcx, 0
.next:
  add rbx, 8
  mov qword [rbx], rax
  loop cr3pageclear
  ret

idtptr:
  dw (idt64.end - idt64) - 1
.ptr:  dq idt64

idt64:
  times 256 dq 0
.end:

gdtptr:
  dw (gdt64.end - gdt64) - 1
.ptr:  dq gdt64

gdt64:
  dq 0 ; null
  .code: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
  .data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41)
.end: