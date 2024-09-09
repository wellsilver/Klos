#ifndef mem_h
#define mem_h

// native memory map type
struct memory_map {
  char type; // 1 = this page allocated, 0=free, >1 = this number of pages are free
};

#include "util/int.h"

uint memoryinit_size(uint type) {
  uint ret;

  switch (type) {
    break;
  }

  return ret;
}

void memoryinit(struct memory_map *ret, uint type) {
  switch (type) {
    break;
  }
}

#endif