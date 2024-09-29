#ifndef discs_h
#define discs_h

#include <int.h>

struct drive {
  uint drives; // 0=nodrive 1=onedrive
  void (*readsector)(uint drive, uint64_t lba, uint sectors, uint16_t *ptr);
};

#include "atapio.h"

/* todo, function to get all drives */

#endif