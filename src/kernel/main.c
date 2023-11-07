asm(".org 0x00010000");

void _start() {
  asm("jmp kernel");
}
// _start() calls the kernel or else the proccessor will go right into one of the headers and triple fault
// the linker script says to enter at kernel but it doesnt for some reason

#include "mem.h"

void kernel() {
  unsigned char *vga = (unsigned char *) 0xb8000;

  uint16_t mmaplen;
  struct e820_entry *mmap;

  memory_init(&mmaplen,mmap);
  
  vga[1] = 15;
  vga[0] = 97+mmaplen; // a

  while (1) asm("hlt");
}