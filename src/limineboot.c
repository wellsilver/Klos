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

__attribute__((used, section(".requests")))
static volatile struct limine_kernel_address_request kernelrequest = {
  .id = LIMINE_KERNEL_ADDRESS_REQUEST,
  .revision = 0
};

__attribute__((used, section(".requests")))
static volatile struct limine_paging_mode_request pageqrequest = {
  .id = LIMINE_PAGING_MODE_REQUEST,
  .revision = 0,
  .mode = LIMINE_PAGING_MODE_X86_64_4LVL
};

// Finally, define the start and end markers for the Limine requests.
// These can also be moved anywhere, to any .c file, as seen fit.

__attribute__((used, section(".requests_start_marker")))
volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests_end_marker")))
volatile LIMINE_REQUESTS_END_MARKER;

// page map level 4
uint64_t pml4[512] __attribute__((aligned(4096)));
// page directory pointer table (program)
uint64_t pdptk[512] __attribute__((aligned(4096)));
// page directory entry (program)
uint64_t pdek[512] __attribute__((aligned(4096)));

// stack
char stack[512*5];

#define rw 1U | 2U

// make all memory rwx and mapped to its physical addresses, so its easier to manipulate
void setuppageing(struct limine_memmap_entry largestfree) {
  struct limine_kernel_address_response kra = *kernelrequest.response;

  // map everything to physical memory
  for (unsigned int loop = 0; loop < 512; loop++) {
    pml4[loop] = 0; // level 4 (512 gigabytes)
    // ^ doesnt exist for now
    pdptk[loop] = 0;
    pdek[loop] = 0;
  }

  unsigned long long allignedbase = (kra.physical_base - (kra.physical_base % 0x200000));

  // map this program so it doesnt become undefined when we put in the new table
  pml4[(kra.virtual_base & ((uint64_t)0x1ff << 39)) >> 39] = (allignedbase + ((uint64_t) pdptk - kra.virtual_base)) | rw;
  pdptk[(kra.virtual_base & ((uint64_t)0x1ff << 30)) >> 30] = (allignedbase + ((uint64_t) pdek - kra.virtual_base)) | rw;
  pdek[(kra.virtual_base & ((uint64_t)0x1ff << 21)) >> 21] = allignedbase | rw | 1<<7;

  uint64_t physical_pml4 = kra.physical_base + ((uint64_t)pml4 - kra.virtual_base);

  // load page table
  asm volatile ("mov cr3, %0" : : "r" (physical_pml4));
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

void main(void);

void kmain(void) {
  // fix stack
  asm volatile ("mov rbp, %0" : : "a" (stack+(512*5)));
  asm volatile ("mov rsp, %0" : : "a" (stack+(512*5)));
  main();
  // even though it uses the stack later, it is never going to reach this part
}

void main(void) {
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

    setuppageing(largestfree);

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