#ifndef klos_mem
#define klos_mem
#include "util/int.h"
#include "inite820.h"
#include "memory/types.h"

long memoryfreeblocks;
long memorysizeblocks;
struct memory_map_entry *memory_map;

/*
memory allocation:

blocks: 40960 size
stored in a memory map which is fully allocated

*/

void memory_init() {
  // code to check if its e820 or some other method here
  initfrome820();
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