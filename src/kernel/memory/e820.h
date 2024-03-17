#ifndef mem_e820_h
#define mem_e820_h

#include "util/int.h"

struct e820_s {
  uint64_t base;
  uint64_t length;
  uint32_t type;
};

struct memory_map *memory_init_e820() {
  struct e820_s *map = (struct e820_s *) 0x7b0f;
  uint16_t map_size  = *(uint16_t *) 0x7b0d;

  struct memory_map *a;
  uint64_t lengthoflargest;
  uint64_t freebytes=0;
  uint64_t allocatedbytes=0;
  // first haved to:
  // count free memory
  // find a place to put the memory map
  for (int loop=0;loop<map_size;loop++) {
    if (map[loop].type = 1) { // if free
      // put the memory map in the largest free area
      if (map[loop].length > lengthoflargest) {lengthoflargest=map[loop].length;a = (struct memory_map *)map[loop].base;}
      freebytes+=map[loop].length;
    } else allocatedbytes+=map[loop].length;
  }

  // create the (native) map
  for (int loop=0;loop<(freebytes+allocatedbytes)/4096;loop++) {
    a[loop].type = 1; // start with all allocated
  }

  return a;
}

#endif