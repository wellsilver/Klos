//asm(".org 0x00010000"); // done by LD

unsigned char *vgacursor;

void _start() {
  vgacursor = (unsigned char *) 0xb8000;
  asm("jmp kernel");
}

// _start() calls the kernel or else the proccessor will go right into one of the headers and triple fault
// the linker script says to enter at kernel but it doesnt for some reason

#include "memory/mem.h"
extern long memoryfreeblocks; // mem.h:10

#include "util/str.h"

void kernel() {
  memory_init();

  char buf[8];
  for (int loop=0;loop<8;loop++) {
    buf[loop] = 0;
  }

  itoa(memoryfreeblocks, buf, 8);

  for (int loop=0;buf[loop/2]!=0;loop+=2) {
    vgacursor[loop] = buf[loop/2];
    vgacursor[loop+1] = 7;
  }

  while (1) asm("hlt");
}