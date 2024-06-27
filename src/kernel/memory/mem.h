#ifndef mem_h
#define mem_h

// native memory map type
struct memory_map {
  char type; // 1 = this page allocated, 0=free, >1 = this number of pages are free
};

#include "util/int.h"
#include "memory/e820.h"

int memoryinit_size() {
  int ret;

  switch (*(uint8_t *)0xFFFF) {
    case 2:
      ret = memoryinit_e820_size();
    break;
  }

  return ret;
}

void memoryinit(struct memory_map *ret) {
  switch (*(uint8_t *)0xFFFF) {
    case 2:
      memoryinit_e820(ret);
    break;
  }
}

#endif