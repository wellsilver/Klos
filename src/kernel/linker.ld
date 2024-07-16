OUTPUT_FORMAT("elf64-x86-64")

ENTRY("start")

SECTIONS {
  .stack = 0x1000;
  . = 0x10000;
# so annoying, tried to put a new section before .text for main.asm to use, but the section wouldnt even be created
  .text = .;
  .data = .;
  .bss  = .;
}