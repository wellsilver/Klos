//asm("jmp kernel"); // cpu jumps to here, removed with main.asm

#include "memory/mem.h"

void kernel() {
  kernel:

  //this displays start via vga just incase if stuck before any display driver init
  (*(uint16_t *) 0xB8000)    = 0x0773;
  (*(uint16_t *) (0xB8000+2))= 0x0774;
  (*(uint16_t *) (0xB8000+4))= 0x0761;
  (*(uint16_t *) (0xB8000+6))= 0x0772;
  (*(uint16_t *) (0xB8000+8))= 0x0774;

  // put it in the stack so we dont haved to deal with the gdt until later. for some reason the gdt is only allowing the first like 8 megabytes
  struct memory_map memory[memoryinit_size()];
  memoryinit(memory);

  while (1) asm("hlt");
}