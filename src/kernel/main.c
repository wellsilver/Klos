asm("jmp kernel"); // cpu jumps to here

#include "memory/mem.h"

void kernel() {
  kernel:
  //this displays start if stuck before any display driver init
  (*(char *) 0xB8000)    = 0x73;
  (*(char *) (0xB8000+2))= 0x74;
  (*(char *) (0xB8000+4))= 0x61;
  (*(char *) (0xB8000+6))= 0x72;
  (*(char *) (0xB8000+8))= 0x74;

  struct memory_map *memory = memory_init();

  while (1) asm("hlt");
}