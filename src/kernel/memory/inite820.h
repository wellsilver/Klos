#ifndef ie820_h
#define ie820_h

#include "util/int.h"
#include "memory/mem.h"

struct e820_entry {
  uint64_t base;
  uint64_t length;
  uint32_t type;
} __attribute__((packed));

void initfrome820() {
  uint16_t mmaplen = *(uint16_t *) 0x7b0d;
  struct e820_entry *mmap = (struct e820_entry *) 0x7b0f;

  int memsize = 0;

  int startslength=0;
  int start=0;
  // find the biggest memory area to store the memory map, get the size of available memory
  for (int loop=0;loop<mmaplen;loop++) {
    memsize += mmap[loop].length;
    if (mmap[loop].type == 1) {
      if (mmap[loop].length > startslength) {
        start = mmap[loop].base;
        startslength = mmap[loop].length;
      }
    }
  }

  memsize /= 40960; // get ammount of blocks

  struct memory_map_entry blank;
  blank.type = 1; // not free

  memory_map = (struct memory_map_entry *) start;
  // initialize the map
  for (int loop=0;loop<memsize;loop++) {
    memory_map[loop] = blank;
  }

  // fill the map
  for (int loop=0;loop<mmaplen;loop++) {

  }
}

#endif