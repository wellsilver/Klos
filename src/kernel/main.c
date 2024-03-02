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
  
  char *newpage = (char *) mempage(1);

  for (int loop=0;loop<1;loop++) ((char *) 0xB8000)[loop] = newpage[loop];

  while (1) asm("hlt");
}