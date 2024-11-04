// find klos and boot it
#include <limine.h>

#include <util/int.h>
#include <util/io.h>
#include <disc/disc.h>

#define NULL 0

__attribute__((used, section(".requests")))
static volatile LIMINE_BASE_REVISION(2);

// The Limine requests can be placed anywhere, but it is important that
// the compiler does not optimise them away, so, usually, they should
// be made volatile or equivalent, _and_ they should be accessed at least
// once or marked as used with the "used" attribute as done here.

__attribute__((used, section(".requests")))
static volatile struct limine_framebuffer_request framebuffer_request = {
  .id = LIMINE_FRAMEBUFFER_REQUEST,
  .revision = 0
};

__attribute__((used, section(".requests")))
static volatile struct limine_memmap_request memmap_request = {
  .id = LIMINE_MEMMAP_REQUEST,
  .revision = 0
};

// Finally, define the start and end markers for the Limine requests.
// These can also be moved anywhere, to any .c file, as seen fit.

__attribute__((used, section(".requests_start_marker")))
volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests_end_marker")))
volatile LIMINE_REQUESTS_END_MARKER;

uint64_t pgd[512] __attribute__((aligned(4096)));
uint64_t pgd[512] __attribute__((aligned(4096)));
uint64_t pgd[512] __attribute__((aligned(4096)));

// make all memory rwx
void setuppageing() {
  

  // load page
  asm volatile ("mov cr3, %0" : : "r" (pgd));

  // disable 5 level paging if limine enabled it
  asm volatile ("mov rax, cr4\n"
                "and rax, 1 << 12\n"
                "mov cr4, rax\n" : : : "rax");
}

struct gpt_entry {
  uint8_t partguid[16];
  uint8_t uniqueguid[16];
  uint64_t startlba;
  uint64_t endlba;
  uint64_t attributes;
  char name[72];
};

ulong findkfslba(struct drive drv, uint64_t *cache) {
  struct gpt_entry gptcache[4];
  uint err;

  err = drv.read(0, 1, 1, cache);
  if (err == 1) return 0; // bad

  if (cache[0] == 6075990659671082565) { // good enough to find gpt descriptor lol. Sometimes theres some padding infront of "efi part", idk why but qemu understands it so
    err = drv.read(0, cache[9], 1, gptcache);
    if (err == 1) return 0; // bad

    // loop through the entire partition list in first lba and look for kfs magic
    uint64_t sectors[4];
    for (uint loop=0;loop<4;loop++) {
      //if (gptcache[loop].partguid[0] == 0) continue; // lets assume its unused

      err = drv.read(0, gptcache[loop].startlba, 1, cache);
      ulong a = gptcache[loop].startlba;
      if (err == 1) return 0; // bad

      if (cache[0] == 654511333969643) return a; // FOUND IT!!!
    }
  } else return 0;
}

// The following will be our kernel's entry point.
// If renaming kmain() to something else, make sure to change the
// linker script accordingly.
void kmain(void) {
  // Ensure the bootloader actually understands our base revision (see spec).
  if (LIMINE_BASE_REVISION_SUPPORTED == 0)
    return;

  if (memmap_request.response != NULL) { // If we have a memory map that should be good enough to start klos, else just catch fire
    setuppageing();

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

    uint lendrives = all_drives(drives);
    if (lendrives == 0) return;

    // TODO make it so it polls every drive, and reads the kernel correctly

    ulong beginlba = findkfslba(drives[0], (uint64_t *) cache);
    if (beginlba == 0) return;
    ulong kernelloc = (*(cache+8)) + beginlba;
    err = drives[0].read(0, kernelloc, 1, cache); // read the highlighted file, which should be the kernel

    // blindly trust that its the kernel, and that it only makes up one range of sectors
    for (uint sectors=0;sectors < *(cache+74+8) - *(cache+74);sectors++)
      drives[0].read(0, *(cache+74) + beginlba + sectors, 1, ((void *) largestfree.base)+(sectors*512));
    

  }
  

  while (1) asm("hlt");
  return;
}