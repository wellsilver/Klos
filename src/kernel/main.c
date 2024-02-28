//asm(".org 0x00010000"); // done by LD

void _start() {
  asm("jmp kernel");
}

// _start() calls the kernel or else the proccessor will go right into one of the headers and triple fault
// the linker script says to enter at kernel but it doesnt for some reason

#include "memory/mem.h"
#include "process.h"
extern long memoryfreeblocks; // mem.h:10
#include "display/display.h"
#include "pci.h"

#include "util/str.h"

void kernel() {
  kernel:
  memory_init();
  process_init();
  
  void *newpage = mempage(1);
  (*(char *) 0xB8000) = 'h';


  while (1) asm("hlt");
}