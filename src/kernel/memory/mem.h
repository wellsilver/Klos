#ifndef mem_h
#define mem_h

// native memory map type
struct memory_map {
  char type; // 1 = this page allocated, 0=free, >1 = this number of pages are free
};

#include "util/int.h"
#include "memory/e820.h"

struct memory_map *memory_init() {
  struct memory_map *ret;

  switch (*(uint8_t *)0xFFFF) {
    case 2:
      ret = memory_init_e820();
    break;
  }

  return ret;
}

#endif