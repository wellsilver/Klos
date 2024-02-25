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

stored in memory_map which describes each page, enum memory_map_style
memory_map is assembled at memory_init

*/

void memory_init() {
  // TODO code to check if its e820 or some other method here
  initfrome820();
}

// get ammount of pages (and resize)
void *mempage(int pages) {

}

// allocate specific page
void *selectpage(int page) {

}

void freepage(int page) {

}

#endif