OUTPUT_FORMAT("elf64-x86-64")

ENTRY("kernel")

SECTIONS {
  .stack = 0x7C00;
  . = 0x10000;
}