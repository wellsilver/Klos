void _start() {
  asm("jmp kernel");
}

#include "memory/mem.h"

void kernel() {
  kernel:
  
  
  (*(char *) 0xB8000) = 'k';

  memory_init();

  while (1) asm("hlt");
}