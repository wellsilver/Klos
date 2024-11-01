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

// translated from src/boot.x86.S
// a new gdt with all of memory listed as readable, writable, and executable
/*
; Access bits
PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0
 
; Flags bits
GRAN_4K       equ 1 << 7
SZ_32         equ 1 << 6
LONG_MODE     equ 1 << 5
 
GDT64: ; 64 bit gdt
  .Null: equ $ - GDT64
    dq 0
  .Code: equ $ - GDT64
    dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
    db 0                                        ; Base (mid, bits 16-23)
    db PRESENT | NOT_SYS | EXEC | RW            ; Access
    db GRAN_4K | LONG_MODE | 0xF                ; Flags & Limit (high, bits 16-19)
    db 0                                        ; Base (high, bits 24-31)
  .Data: equ $ - GDT64
    dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
    db 0                                        ; Base (mid, bits 16-23)
    db PRESENT | NOT_SYS | RW                   ; Access
    db GRAN_4K | SZ_32 | 0xF                    ; Flags & Limit (high, bits 16-19)
    db 0                                        ; Base (high, bits 24-31)
  .TSS: equ $ - GDT64
    dd 0x00000068
    dd 0x00CF8900
  .Pointer:
    dw $ - GDT64 - 1
    dq GDT64
*/
struct _gdt64 {
  uint64_t d0;
  uint32_t d1;
  uint8_t d2;
  uint8_t d3;
  uint8_t d4;
  uint8_t d5;
  uint32_t d6;
  uint8_t d7;
  uint8_t d8;
  uint8_t d9;
  uint8_t dA;
  uint32_t dB;
  uint32_t dC;
} __attribute__((packed));
struct _gdt64ptr {
  uint16_t size;
  void *ptr;
} __attribute__((packed));

// incase your wondering, yes I hate this
__attribute__((used, section(".text")))
static volatile struct _gdt64 gdt = {
  .d0 = 0,
  .d1 = 0xFFFF,
  .d2 = 0,
  .d3 = 1 << 7 | 1 << 4 | 1 << 3 | 1 << 1,
  .d4 = 1 << 7 | 1 << 5 | 0xF,
  .d5 = 0,
  .d6 = 0xFFFF,
  .d7 = 0,
  .d8 = 1 << 7 | 1 << 4 | 1 << 1,
  .d9 = 1 << 7 | 1 << 6 | 0xF,
  .dA = 0,
  .dB = 0x00000068,
  .dC = 0x00CF8900
};
__attribute__((used, section(".text")))
static volatile struct _gdt64ptr gdtptr = {
  .size = sizeof(struct _gdt64) - 1,
  .ptr = &gdt
};


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

    asm volatile ("lgdt gdtptr");

    // blindly trust that its the kernel, and that it only makes up one range of sectors
    for (uint sectors=0;sectors < *(cache+74+8) - *(cache+74);sectors++)
      drives[0].read(0, *(cache+74) + beginlba + sectors, 1, ((void *) largestfree.base)+(sectors*512));
    
  }
  

  while (1) asm("hlt");
  return;
}