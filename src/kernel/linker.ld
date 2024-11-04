OUTPUT_FORMAT("elf64-x86-64")

ENTRY("start")

SECTIONS
{
  .stack = 0x1000;
  . = 0x10000;
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
}