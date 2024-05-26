#ifndef mem_e820_h
#define mem_e820_h

#include "util/int.h"

struct e820_s {
  uint64_t base;
  uint64_t length;
  uint32_t type;
};

struct memory_map *memoryinit_e820() {
  struct e820_s *biosmap = (struct e820_s *) 0x7b0f;
  uint16_t map_size  = *(uint16_t *) 0x7b0d;

  struct memory_map *map;
  uint64_t freebytes=0;
  uint64_t allocatedbytes=0;

  for (int loop=0;loop<map_size;loop++) {
    if (biosmap->type == 1) {
      freebytes += biosmap->length;
    } else {
      allocatedbytes += biosmap->length;
    }
  }

  allocatedbytes++;

  return map;
}

#endif