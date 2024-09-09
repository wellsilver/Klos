//asm("jmp kernel"); // cpu jumps to here, replaced with main.asm. Yes this worked great and had zero problems, I am not kidding.

#include "memory/mem.h"

void kernel() {
  kernel:
  uint type;
  // put it in the stack so we dont haved to deal with the gdt until later. for some reason the gdt is only allowing the first like 8 megabytes
  struct memory_map memory[memoryinit_size(type)];
  memoryinit(memory, type);



  while (1) asm("hlt");
}