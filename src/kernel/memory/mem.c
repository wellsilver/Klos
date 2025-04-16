#include <memory/mem.h>
#include <int.h>

void meminit(struct memregion *a, uint len) {
  // First, looking for the largest block of free memory
  struct memregion largest = a[0];
  for (uint i=1;i<len;i++)
    if (a[i].size > largest.size) largest = a[i];
  
  
}