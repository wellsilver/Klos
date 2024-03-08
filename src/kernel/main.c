asm("jmp kernel"); // cpu jumps to here

#include "memory/mem.h"

void kernel() {
  kernel:
  
  (*(char *) 0xB8000) = 'k';

  struct memory_map *memory = memory_init();

  while (1) asm("hlt");
}