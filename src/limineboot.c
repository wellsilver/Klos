// find klos and boot it
#include "int.h"
#include "io.h"
#include <limine.h>
#define NULL 0

__attribute__((used, section(".requests")))
static volatile LIMINE_BASE_REVISION(2);

// The Limine requests can be placed anywhere, but it is important that
// the compiler does not optimise them away, so, usually, they should
// be made volatile or equivalent, _and_ they should be accessed at least
// once or marked as used with the "used" attribute as done here.

/*
__attribute__((used, section(".requests")))
static volatile struct limine_framebuffer_request framebuffer_request = {
  .id = LIMINE_FRAMEBUFFER_REQUEST,
  .revision = 0
};
*/

__attribute__((used, section(".requests")))
static volatile struct limine_memmap_request memmap_request = {
  .id = LIMINE_MEMMAP_REQUEST,
  .revision = 0
};

// Finally, define the start and end markers for the Limine requests.
// These can also be moved anywhere, to any .c file, as seen fit.

__attribute__((used, section(".requests_start_marker")))
static volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests_end_marker")))
static volatile LIMINE_REQUESTS_END_MARKER;

void ata_read(uint64_t sector, uint16_t sectors, uint16_t *to) {
  // 48 bit PIO. I wodner why its backwards? I hope its not because of some big-little endian thing, I just wish everything was little endian as a irrequivable rule
  outb(0x01f6, 0x50); // master drive
  outb(0x01f2, ((uint8_t *) &sectors)[1]); // higher byte of sectors
  outb(0x01f3, ((uint8_t *) &sector)[5]); // sixth lba byte
  outb(0x01f3, ((uint8_t *) &sector)[4]); // fifth lba byte
  outb(0x01f3, ((uint8_t *) &sector)[3]); // fourth lba byte
  // lower bytes
  outb(0x01f2, ((uint8_t *) &sectors)[0]); // higher byte of sectors
  outb(0x01f3, ((uint8_t *) &sector)[2]); // sixth lba byte
  outb(0x01f3, ((uint8_t *) &sector)[1]); // fifth lba byte
  outb(0x01f3, ((uint8_t *) &sector)[0]); // fourth lba byte
  outb(0x1F7, 0x24); // READ SECTORS EXT
  
  for (int loop=0;loop<256;loop++) {
    to[loop] = inw(0x0f0);
  }
}

// The following will be our kernel's entry point.
// If renaming kmain() to something else, make sure to change the
// linker script accordingly.
void kmain(void) {
  // Ensure the bootloader actually understands our base revision (see spec).
  if (LIMINE_BASE_REVISION_SUPPORTED == 0)
    return;

  if (memmap_request.response != NULL) { // If we have a memory map that should be good enough to start klos, else just catch fire
    struct limine_memmap_entry largestfree;
    largestfree.base = 0;
    largestfree.length = 0;
    uint64_t highest;
    uint64_t numpages;

    for (int loop=0;loop<memmap_request.response->entry_count;loop++) {
      struct limine_memmap_entry *i = memmap_request.response->entries[loop];

      if (i->type == LIMINE_MEMMAP_USABLE) {
        if (i->length > largestfree.length) {
          largestfree = *i;
        }
        if (i->base + i->length > highest) highest = i->base+i->length;
      }
    }

    numpages = highest/4096;

    // find the sector with kfs on it
    uint64_t currentsect = 2;
    uint16_t cache[256];
    for (int loop=0;loop<256;loop++) cache[0] = 0;

    ata_read(currentsect, 1, cache);
    if (*(uint64_t *) cache != 5641124985470729451) {// if first characters is limine
      return;
    }
  }

  while (1) asm("hlt");
  return;
}