OUTPUT_FORMAT("binary")

ENTRY("_start")

SECTIONS {
  . = 0x00010000;
  .text : {
    *(.text)
  }
}