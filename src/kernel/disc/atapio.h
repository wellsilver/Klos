#ifndef discsatapio_h
#define discsatapio_h

#include <int.h>
#include <io.h>
#include "disc.h"

void atapio_read(uint drive, uint64_t lba, uint sectors, uint16_t *ptr) {
  uint8_t b = inb(0x1F7);
  if (b == 0xFF) return; // error?
  if (b == 0x80) return;

  outb(0x1F6, 0x40); // master
  outb(0x1F1, 0x00); // write 0x00 to the FEATURES register
  outb(0x1F2, 0x01); // write 0x01 to the Sector Count register
  outb(0x1F3, (unsigned char) lba); // Sector number or LBA Low, most likely LBA Low (but see comments below)
  outb(0x1F4, (unsigned char)(lba >> 8)); // Cyl Low number or LBA Mid
  outb(0x1F5, (unsigned char)(lba >> 16)); // Cyl High number or LBA High
  outb(0x1F7, 0x20); // Send command, See note [2] below

  while (inb(0x1F7) == 80); // wait until ready
  
  for (uint loop=0;loop<256;loop++) {
    ptr[loop] = inw(0x1F0);
  }
  lba = 0;
}

// should be able to be included by a bootloader and called
struct drive atapio_hasdrive() {
  // check if the ports work and are native atapio, if not return nothing
  struct drive ret;
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
  if (stat==0) {ret.drives = 0;return ret;}
  while (inb(0x1F7) == 80); // wait until ready
  for (int loop=0;loop<256;loop++) inw(0x1F0); // read garbage

  ret.drives = 1;
  ret.readsector = atapio_read;
  return ret;
}

#endif