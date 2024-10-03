// find klos and boot it
#include "int.h"
#include "io.h"
#include <limine.h>
#include <../disc/disc.h>

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

    uint8_t cache[512];
    struct drive drives[16];
    uint err;

    uint lendrives = all_drives(drives); //replace with disc_alldrives() when its implemented
    if (lendrives == 0) return;

    err = drives[0].read(0, 1, 1, (uint16_t *) cache);
    if (err == 1) return;
    if (cache[0] == 'e' || cache[2] == 'e') { // good enough to find gpt descriptor lol. Sometimes theres some padding infront of "efi part", idk why

    } else return;
    
  }
  

  while (1) asm("hlt");
  return;
}