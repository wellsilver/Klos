OUTPUT_FORMAT("elf64-x86-64")

ENTRY("entry")

SECTIONS
{
  . = 0x1000;
  .asm : { *(.asm) }
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
  
# 64 KB of stack space
  .stack : ALIGN(4096) {
    . = . + 0x10000;
    stackend = .;
  }
}