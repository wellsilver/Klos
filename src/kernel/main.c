asm("jmp kernel"); // cpu jumps to here

#include "memory/mem.h"

void kernel() {
  kernel:

  //this displays start via vga just incase if stuck before any display driver init
  (*(uint16_t *) 0xB8000)    = 0x0773;
  (*(uint16_t *) (0xB8000+2))= 0x0774;
  (*(uint16_t *) (0xB8000+4))= 0x0761;
  (*(uint16_t *) (0xB8000+6))= 0x0772;
  (*(uint16_t *) (0xB8000+8))= 0x0774;

  struct memory_map *memory = memoryinit();

  while (1) asm("hlt");
}