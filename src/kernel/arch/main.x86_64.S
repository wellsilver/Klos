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
  nop
  ; stack setup, space is reserved by the linker script
  lea rsp, [rel stackend]
  dec rsp
  cli ; the IDT is empty

  ; add pagefault handler
  lea rbx, [rel idt64 + (0xE*16)]
  mov rax, pagefault ; get virtual address
  mov word [rbx], ax               ; offset
  mov word [rbx+2], 0x08           ; code segment selector
  mov byte [rbx+4], 0              ; IST (0 = no special stack)
  mov byte [rbx+5], 0x8E           ; Present, DPL=0, Interrupt gate
  shr rax, 16
  mov word [rbx+6], ax             ; offset
  shr rax, 16
  mov dword[rbx+8], eax            ; offset
  
  ; new IDT
  lea rbx, [rel idt64]
  lea rax, [rel idtptr + 2]
  mov qword [rax], rbx
  sub rax, 2
  lidt [rax]

  sti

  ; new GDT
  lea rbx, [rel gdt64]
  lea rax, [rel gdtptr + 2]
  mov qword [rax], rbx
  sub rax, 2
  push rax ; only lgdt after setting up the tss
  
  ; setup tss in GDT
  lea rax, [rel tss64]
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

  ; create a new page map
  call newcr3

  ; ensure cache is enabled, write protect enabled
  mov rax, cr0
  or rax, 1 << 16 ; enable write protect
  and rax, ~(1 << 30) ; zero cache disable bit (if cr0.cd is zero then cache is enabled)
  mov cr0, rax

  mov rax, kernel
  jmp rax

entryend:

; map the parts of pagemap reserved for data to real memory when needed
pagefault:
  hlt
  iretq

; pagemap (1 l4, 2 l3, 2 l2)
newcr3:
  ; clear the memory
  push rdi
  lea rdi, [rel pagemap]
  xor rax, rax
  mov rcx, 0x5000
  rep stosb
  pop rdi
  ; get addr
  lea rbx, [rel pagemap]
  mov rcx, rbx
  ; l4 = rbx, l3 0 = rbx+0x1000, l3 1 = rbx+0x2000, l2 0 = rbx+0x3000, l2 1 = rbx+0x4000
  ; l3 1 and l2 1 are for this code
  ; l3 2 and l2 2 are for data (and set by the pagefault handler)
  ; all memory is mapped to real memory
  ; kernel is mapped to 0xFF8000000000 (l4 511 l3 0 l2 0)
  
  ;; map kernel
  ; l4 to first l3
  lea rax, [rel pagemap + 0x1000 + 1] ; pointer to l3 0, with present bit
  lea rbx, [rel pagemap + (511*8)] ; pml4[511]
  mov qword [rbx], rax
  ; l3 to l2
  lea rax, [rel pagemap + 0x3000 + 0x01] ; pointer to l2 0 with present and page size (1 << 7) set 
  lea rbx, [rel pagemap + 0x1000] ; l3[0]
  mov qword [rbx], rax ; map the level 3 entry to the level 2 entry
  ; l2 to mem
  mov rax, rdi ; pointer to the physical memory with present and pagesize set
  or rax, 1 | 1<<7 
  lea rbx, [rel pagemap + 0x3000] ; l2[0]
  mov qword [rbx], rax
  
  ; map this part to memory (so we can continue working here on the new cr3)
  mov rax, rdi
  lea rbx, [rel pagemap]
  ; get l4 position and set it to l3 1
  and rax, 0xFF8000000000 ; zero all bits that arent part of l4
  shr rax, 48-9
  shl rax, 3 ; (multiply by 8) todo combine with shr before
  add rbx, rax
  lea rax, [rel pagemap + 0x2000] ; to l3 1
  or rax, 1
  mov qword [rbx], rax
  ; get l3 position and set it to l2 1
  mov rax, rdi
  lea rbx, [rel pagemap + 0x2000] ; to l3 1
  and rax, 0x007F80000000 ; zero all bits that arent part of l4
  shr rax, 48-9-9
  shl rax, 3 ; (multiply by 8) todo combine with shr before
  add rbx, rax
  lea rax, [rel pagemap + 0x4000] ; to l2 1
  or rax, 1
  mov qword [rbx], rax
  ; get l2 position and set it to the memory
  mov rax, rdi
  lea rbx, [rel pagemap + 0x4000] ; to l2 1
  and rax, 0x00003fe00000
  shr rax, 48-9-9-9
  shl rax, 3 ; (multiply by 8) todo combine with shr before
  add rbx, rax
  mov rax, rdi
  or rax, 1 | 1<<7
  mov qword [rbx], rax

  lea rax, [rel pagemap]
  mov cr3, rax

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