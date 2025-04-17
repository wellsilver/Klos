#ifndef mem_c
#define mem_c

#include <int.h>

struct memregion {
  uint64_t base,size;
} PACKED;

extern void meminit(struct memregion *, uint len);


#endif