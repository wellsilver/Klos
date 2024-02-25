#ifndef typesh
#define typesh

#include "util/int.h"

enum memory_map_style {
  mm_free = 0,
  mm_allocated = 1,
  mm_system = 2
};

struct memory_map_entry {
  char type;
};

#endif