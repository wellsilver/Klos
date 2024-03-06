#ifndef mem_h
#define mem_h

struct memory_map {
  char type; // 1 = this page allocated, 0=free, >1 = this number of pages are free
};

struct memory_map *memory_init() {
  
}

#endif