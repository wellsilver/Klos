#ifndef discs_c
#define discs_c

#include <int.h>

struct drive {
  // how large the drive is
  ulong sizelba;
  // 1 on error
  uint (*read)(uint drive, uint64_t lba, uint sectors, void *ptr);
};

uint all_drives(struct drive *drives);

#endif