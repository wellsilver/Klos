OUTPUT_FORMAT("elf64-x86-64")

ENTRY("entry")

SECTIONS
{
  . = 0x100000;
  .text : { *(.text.entry) *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
  
# 64 KB of stack space
  .stack : ALIGN(4096) {
    . = . + 0x10000;
    stackend = .;
  }
}