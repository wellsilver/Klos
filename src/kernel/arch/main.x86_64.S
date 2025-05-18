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
; Operates in real memory, rip uknown, uses argument in rdi to map virtual memory for c code
entry:
  ; stack setup, space is reserved by the linker script
  mov rsp, stackend
  dec rsp

  ; if not working after being loaded to virtual memory, it is because idtptr and gdtptr are not adjusted
  ; new IDT
  mov rax, rdi
  add rax, idtptr - 0xFF8000000000
  lidt [rax]

  ; new GDT
  mov rax, rdi
  add rax, gdtptr - 0xFF8000000000
  lgdt [rax]
  
  ; create a new page map
  call newcr3

  ; ensure cache is enabled, write protect enabled
  mov rax, cr0
  or rax, 1 << 16 ; enable write protect
  and rax, ~(1 << 30) ; zero cache disable bit (if cr0.cd is zero then cache is enabled)
  mov cr0, rax

  ; flush cache writes for coproccessors (is this a good idea?)
  wbnoinvd

  jmp kernel

entryend:

; pagemap (1 l4, 2 l3, 2 l2)
newcr3:
  ; get addr
  mov rbx, rdi
  hlt
  add rbx, pagemap - 0xFF8000000000
  push rbx
  ; l4 = rbx, l3 1 = rbx+0x1000, l3 2 = rbx+0x2000, l2 1 = rbx+0x3000, l2 2 = rbx+0x4000
  ; l3 1 and l2 1 are for this code
  ; l3 2 and l2 2 are for data (and set by the pagefault handler)
  ; all memory is mapped to real memory
  ; kernel is mapped to 0xFF8000000000 (l4 512 l3 0 l2 0)
  
  ;; map kernel
  ; l4 (kernel map) to first l3
  mov rax, rbx
  add rax, 0x1000 | 1 ; to the first l3
  add rbx, 511*8 ; get the 512'th entry (where the kernel is mapped to)
  mov qword [rbx], rax
  ; l3 to l2
  mov rbx, qword [rsp+8] ; restore rbx to the page table base
  add rbx, 0x1000
  mov rax, rbx
  add rax, 0x3000
  or rax, 1
  mov qword [rbx], rax ; map the level 3 entry to the level 2 entry
  ; l2 to mem
  pop rbx ; restore rbx to page table base
  mov rax, rbx
  add rax, 0x3000
  or rax, 1 | 1<<7
  mov qword [rbx], rax

  hlt

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

times 4096-($-$$) nop