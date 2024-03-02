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
in memory_map_style anything above 0 isnt free

*/

void memory_init() {
  // TODO code to check if its e820 or some other method here
  initfrome820();
  memory_map[0].type = 2; // the first block when described will be a null pointer, so lets just ignore it
}

// get x pages (and resize)
void *mempage(int pages) {
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

  register uint64_t start_ = (uint64_t) start/4096;
  memory_map[start_].type = allocated+10; // describe how many blocks are allocated
  start_++;
  for (loop=start_;loop<start_+allocated;loop++) { // allocate all used blocks
    memory_map[loop].type = 2; // used
  }
  return start;
}

// allocate specific page
void *selectpage(int page) {

}

void freepage(int page) {

}

#endif