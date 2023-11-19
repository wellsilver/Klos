#ifndef typesh
#define typesh

#include "util/int.h"

struct memory_map_entry {
  char type;
};

struct e820_entry {
  uint64_t base;
  uint64_t length;
  uint32_t type;
} __attribute__((packed));

#endif