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
  .stack : {
    . = . + 0x10000 + (4096-(. % 4096));
    stackend = .;
  }
# pagemap (1 l4, 2 l3, 2 l2)
  .map : {
    . = . + 0x5000;
    mapend = .;
  }
}