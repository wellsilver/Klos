asm(".org 0x00010000");

void _start() {
  asm("jmp kernel");
}
// _start() calls the kernel or else the proccessor will go right into one of the headers and triple fault
// the linker script says to enter at kernel but it doesnt for some reason

#include "mem.h"

void kernel() {
  unsigned register char *vga = (unsigned char *) 0xb8000;

  uint16_t mmaplen = *(uint16_t *) 0x7b0d;
  struct e820_entry *mmap = (struct e820_entry *) 0x7b0f;

  vga[0] = 'a' + mmaplen;
  vga[1] = 7;

  while (1) asm("hlt");
}