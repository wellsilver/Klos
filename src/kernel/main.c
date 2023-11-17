asm(".org 0x00010000");

unsigned char *vgacursor;

void _start() {
  vgacursor = (unsigned char *) 0xb8000;
  asm("jmp kernel");
}

// _start() calls the kernel or else the proccessor will go right into one of the headers and triple fault
// the linker script says to enter at kernel but it doesnt for some reason

#include "mem.h"
#include "util/str.h"

void kernel() {
  uint16_t mmaplen = *(uint16_t *) 0x7b0d;
  struct e820_entry *mmap = (struct e820_entry *) 0x7b0f;
  int loop;

  int freemem = 0;
  for (loop=0;loop<mmaplen;loop++) {
    if (mmap[loop].type == 1) {
      freemem += mmap[loop].length;
    }
  }
  char buf[24];
  for (loop=0;loop<24;loop++) {
    buf[loop] = 0;
  }
  itoa(freemem, buf, 24);
  
  for (loop=0;buf[loop/2]!=0;loop+=2) {
    vgacursor[loop] = buf[loop/2];
    vgacursor[loop+1] = 7;
  }

  while (1) asm("hlt");
}