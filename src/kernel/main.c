asm(".org 0x00010000");

void _entry() {
  asm("jmp kernel");
}
// _entry() calls the kernel or else the proccessor will go right into one of the headers and triple fault

#include "mem.h"

void kernel() {
  unsigned char *vga = (unsigned char *) 0xb8000;

  uint16_t mmaplen;
  struct e820_entry *mmap;

  memory_init(&mmaplen,mmap);

  vga[1] = 15;
  vga[0] = 97+mmaplen;

  while (1) asm("hlt");
}