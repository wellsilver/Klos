; this is linked with main.c for compability with random shit, no relation to ../boot.asm
; also include other asm files from here, so we dont need to compile everything separately


; gdt sorting and everything else here
section .text
global entry
extern kernel
extern stackend

; setup before kernel. Preserve registers!! as this is just undoing all the uefi (or other bootloader) set stuff before actually entering kernel
entry:
  ; stack setup, space is reserved by the linker script
  mov rsp, stackend
  dec rsp
  ; ensure cache is enabled, write protect enabled
  mov rax, cr0
  or rax, 1 << 16 ; enable write protect
  and rax, ~(1 << 30) ; zero cache disable bit (if cr0.cd is zero then cache is enabled)
  mov cr0, rax
  ; flush cache for faster writes (is this a good idea?)
  wbnoinvd

  
  jmp kernel