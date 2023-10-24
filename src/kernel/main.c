asm(".org 0x00010000");

void _entry() {
  asm("jmp kernel");
}
// _entry() calls the kernel or else the proccessor will go right into one of the headers and triple fault

#include "mem.h"

void kernel() {
asm("kernel:");
  unsigned char *vga = (unsigned char *) 0xb8000;

  vga[1] = 15;
  vga[0] = 'h';
  vga[3] = 15;
  vga[2] = 'i';

  memory_init();

  while (1) asm("hlt");
}