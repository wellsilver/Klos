OUTPUT_FORMAT("elf64-x86-64")

ENTRY("kernel")

SECTIONS {
  .stack = 0x1000;
  . = 0x10000;
  .text = .;
  .data = .;
  .bss  = .;
}