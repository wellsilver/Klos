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

// get x pages (and resize)
static void *mempage(int pages) {
  uint64_t loop=0;
  void *start;
  int allocated = 0;
  do {
    if (memory_map[loop].type==0 && (uint64_t) start == 0) // set start to the first free block in path
      start = (void *) (loop*4096);
    if (memory_map[loop].type==0) allocated++; // check if the next block is free
    else {start = (void *) 0;allocated = 0;}   // if the next block si not free, reset start and allocated
    
    loop++;
  } while (loop < memorysizeblocks && allocated != pages); // until goal, or out of memory
  if (allocated != pages) start = (void *) 0;
  return start;
}


// allocate specific page
void *selectpage(int page) {

}

void freepage(int page) {

}

#endif