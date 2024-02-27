OUTPUT_FORMAT("elf64-x86-64")

ENTRY("kernel")

SECTIONS {
  .stack = 0x00000500;
  . = 0x10000;

}