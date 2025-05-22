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
; TODO replace all mov register, rdi with lea register, [rel memloc]
entry:
  ; stack setup, space is reserved by the linker script
  lea rsp, [rel stackend]
  dec rsp

  ; new IDT
  mov rax, rdi
  mov rbx, rdi
  add rbx, idt64  - 0xFF8000000000
  add rax, idtptr - 0xFF8000000000 + 2
  mov qword [rax], rbx
  sub rax, 2
  lidt [rax]

  ; new GDT
  mov rax, rdi
  mov rbx, rdi
  add rbx, gdt64  - 0xFF8000000000
  add rax, gdtptr - 0xFF8000000000 + 2
  mov qword [rax], rbx
  sub rax, 2
  push rax ; only lgdt after setting up the tss
  
  ; setup tss in GDT
  mov rax, rdi
  add rax, tss64 - 0xFF8000000000
  add rbx, 24 ; rbx is still at the gdt base
  mov word [rbx], 0x67; size of long mode TSS (set tss.limit)
  add rbx, 2 ; to tss.base(bits 0->16)
  mov word [rbx], ax ; write to tss.base(bits 0->16)
  shl rax, 16
  add rbx, 3 ; to the access byte
  mov word [rbx], 0x09 | 1<<7 ; write the access byte
  add rbx, 2 ; to tss.base(bits 16->64)
  mov dword [rbx], eax ; write to tss.base(bits 16->64) but writes only 32 bits as only 48 bits (16+32) supported
  
  pop rax
  lgdt [rax]

  ; setup GDT
  push 0x08
  xor rax, rax
  lea rax, [rel .reloadcs] ; example of using lea for relative addressing (because it couldve been used before)
  push rax
  retfq ; far return, pop RIP then pop CS
.reloadcs:
  mov ax, 0x10 ; gdt.data
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  add ax, 8 ; gdt.tss
  ltr ax ; gdt.tss
  hlt ; HALT
  
  ; create a new page map
  call newcr3

  ; ensure cache is enabled, write protect enabled
  mov rax, cr0
  or rax, 1 << 16 ; enable write protect
  and rax, ~(1 << 30) ; zero cache disable bit (if cr0.cd is zero then cache is enabled)
  mov cr0, rax

  ; never touching this code or anything before it again
  serialize
  wbinvd

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
  .null:
    dq 0 ; null
  .code: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
  .data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41)
  .tss: equ $ - gdt64
    dq 0x9 << 40 ; 0x9 access byte (64-bit TSS (Available)), no idea what available/busy means but its definitely required
    dq 0
.end:

tss64:
  times 0x68 db 0
.end:

times 4096-($-$$) nop