asm("jmp kernel"); // cpu jumps to here

#include "memory/mem.h"

void kernel() {
  kernel:
  //this displays start if stuck before any display driver init
  (*(char *) 0xB8000)    = 0x0773;
  (*(char *) (0xB8000+2))= 0x0774;
  (*(char *) (0xB8000+4))= 0x0761;
  (*(char *) (0xB8000+6))= 0x0772;
  (*(char *) (0xB8000+8))= 0x0774;

  struct memory_map *memory = memory_init();

  while (1) asm("hlt");
}