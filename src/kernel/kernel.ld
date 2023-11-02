
MEMORY
{
  ram (rwx) : ORIGIN = 0x00010000, LENGTH = 1M
}

SECTIONS
{
  .text : { *(.text) } > ram
}