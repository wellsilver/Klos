#ifndef discsatapio_h
#define discsatapio_h

#include <int.h>
#include <io.h>
#include "disc.h"

uint atapio_read48(uint drive, uint64_t lba, uint sectors, void *ptr) {
  uint8_t status = inb(0x1F7);
  if (status == 0xFF) return 1; // error?
  if (status == 0x80) return 1; // drive is busy

  outb(0x1F6, 0xE0  | ((lba >> 24) & 0x0F)); // master and upper 4 bits
  outb(0x1F2, 0x01); // write 0x01 to the Sector Count register
  outb(0x1F3, (unsigned char) lba); // Sector number or LBA Low, most likely LBA Low (but see comments below)
  outb(0x1F4, (unsigned char)(lba >> 8)); // Cyl Low number or LBA Mid
  outb(0x1F5, (unsigned char)(lba >> 16)); // Cyl High number or LBA High
  outb(0x1F7, 0x20); // Send command, See note [2] below

  for (status = 80;status == 80;status=inb(0x1F7));
  if (status != 88) return 1; // error


  for (uint loop=0;loop<256;loop++) {
    ((uint16_t *) ptr)[loop] = inw(0x1F0);
  }
  return 0;
}

// check for master drive - should be able to be included by a bootloader and called
struct drive atapio_hasdrive() {
  // check if the ports work and are native atapio, if not return nothing
  struct drive ret;
  ret.read = 0;
  uint16_t stat;

  // check master drive
  outb(0x1F6, 0xA0);
  outb(0x1F2, 0);
  outb(0x1F3, 0);
  outb(0x1F4, 0);
  outb(0x1F5, 0);
  outb(0x1F7, 0xEC); // ATAPIO IDENTIFY
  stat=inb(0x1F7);
  // no drive :(
  if (stat==0) return ret;
  // drives that arent up to spec lets just ignore
  while (inb(0x1F7) == 80); // wait until ready
  uint16_t cache[256];
  for (int loop=0;loop<256;loop++) cache[loop] = inw(0x1F0); // read status

  // if it doesnt support LBA48 then return no drive. no support for other stuff yet
  ret.sizelba = ((uint64_t *) cache)[25];
  if (ret.sizelba == 0) return ret;

  ret.read = atapio_read48;
  return ret;
}

#endif