#ifndef klos_mem
#define klos_mem
#include "util/int.h"

struct e820_entry {
  uint64_t base;
  uint64_t size;
  uint32_t type;
} __attribute__((packed));

struct e820_entry entries[128];

void mscan() {

}

void memory_init() {
  mscan();
}

// low level unrestricted allocation
void *memmalloc(unsigned int size) {

}

// low level unrestricted freeing
void memfree(void *ptr) {

}

// allocate specific page
void *selectpage(int page) {

}

#endif