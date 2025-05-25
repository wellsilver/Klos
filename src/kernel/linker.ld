OUTPUT_FORMAT("elf64-x86-64")

ENTRY("entry")

SECTIONS
{
# 0xFF8000000000 is 512'th entry in pml4
  . = 0xFF8000000000;
  .asm : { *(.asm) }
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
# 64 KB of stack space
  .stack : {
    . = . + 0x10000;
    stackend = .;
  }
# pagemap (1 l4, 2 l3, 2 l2)
  .pagemap : ALIGN(4096) {
    pagemap = .;
    . = . + 0x6000;
    mapend = .;
  }
}