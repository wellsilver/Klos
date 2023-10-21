#ifndef klos_mem
#define klos_mem
#include "util/int.h"

struct e820_entry {
  uint64_t base;
  uint64_t size;
  uint32_t type;
} __attribute__((packed));

void memory_init() {
  
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

void freepage(int page) {

}

#endif