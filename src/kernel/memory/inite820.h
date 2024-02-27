#ifndef ie820_h
#define ie820_h

#include "memory/types.h"
#include "util/int.h"
#include "memory/mem.h"

extern long memoryfreeblocks; // mem.h:10
extern long memorysizeblocks; // mem.h:11
extern struct memory_map_entry *memory_map; // mem.h:12

struct e820_entry {
  uint64_t base;
  uint64_t length;
  uint32_t type;
} __attribute__((packed));

void initfrome820() {
  uint16_t mmaplen = *(uint16_t *) 0x7b0d;
  struct e820_entry *mmap = (struct e820_entry *) 0x7b0f;

  memoryfreeblocks=0;
  memorysizeblocks=0;

  long memsize = 0;

  long startslength=0;
  long start=0;
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
    if (mmap[loop].type == 1) {
      for (int loop2=0;loop2<mmap[loop].length/40960;loop2++) {
        memoryfreeblocks++;
        memory_map[(mmap[loop].base/40960) + loop2].type = 0; // free
      }
    }
  }

  // allocate the memory map to the memory map
  for (int loop=0;loop < (memsize*sizeof(struct memory_map_entry));loop++) {
    memoryfreeblocks--;
    memory_map[(start+loop) / 40960].type = 2; // allocated by system
  }
}

#endif