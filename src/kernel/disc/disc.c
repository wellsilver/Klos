#ifndef discs_c
#define discs_c

#include <int.h>

struct drive {
  // how large the drive is
  ulong sizelba;
  // 1 on error
  uint (*read)(uint drive, uint64_t lba, uint sectors, void *ptr);

};

#include "atapio.c"

// writes to (struct drive *drives), returns zero (error) or how many drives there are
uint all_drives(struct drive *drives) {
  // ask all drivers what drives they have
  uint lendrives = 0;
  struct drive tempdrive;

  // ask ata pio driver
  tempdrive = atapio_hasdrive();
  if (tempdrive.read != 0) drives[lendrives] = tempdrive;
  lendrives++;

  return lendrives;
}

#endif