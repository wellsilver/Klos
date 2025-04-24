// POSIX-UEFI

#include <uefi.h>
#include <kfs/kfs.h>

struct ioandoffset {
  efi_block_io_t *disc;
  uint64_t lba;
  uint64_t highlighted;
};

void errexit(char *str) {
  printf("klos bootloader: %s\n", str);
  sleep(5);
  exit(-1);
}

struct gptpart {
  uint8_t typeguid[16];
  uint8_t unique[16];
  uint64_t start,end;
  uint64_t attribute;
  char name[72];
};

struct memregion {
  uint64_t base,size;
} __attribute__((packed));

struct ioandoffset findkfs() {
  efi_guid_t bioGuid = EFI_BLOCK_IO_PROTOCOL_GUID;
  efi_handle_t blockiohandles[24];
  efi_block_io_t *blockio[24];
  uintn_t handle_size = sizeof(blockiohandles);

  efi_status_t err = BS->LocateHandle(ByProtocol, &bioGuid, NULL, &handle_size, (void **) &blockiohandles);
  handle_size /= sizeof(blockiohandles[0]);
  if (EFI_ERROR(err) || handle_size == 0) errexit("Blockio required\n");

  for (unsigned int loop=0;loop<handle_size;loop++) {
    err = BS->HandleProtocol(blockiohandles[loop], &bioGuid, (void **) &blockio[loop]);
    if (EFI_ERROR(err)) errexit("Bad blockio handle\n");
  }

  char *kfs = "KFS";
  // First search the logical partitions, it seems like computers will only create logical partition/fake drive things for the boot drive
  for (unsigned int loop=0;loop<handle_size;loop++) {
    if (blockio[loop]->Media->LogicalPartition && blockio[loop]->Media->MediaPresent) {
      uint8_t cache[blockio[loop]->Media->BlockSize];
      err = blockio[loop]->ReadBlocks(blockio[loop], blockio[loop]->Media->MediaId, 0, blockio[loop]->Media->BlockSize, cache);
      if (EFI_ERROR(err)) errexit("Broken Part\n");
      if (memcmp(kfs, cache+3, 3)==0) return (struct ioandoffset) {blockio[loop], 0, ((struct kfs_bootsec *) cache)->highlightedfile}; // Check for header
    }
  }
  char *efiheader = "EFI PART";
  // Time to search every drive
  for (unsigned int loop=0;loop<handle_size;loop++) {
    if (!blockio[loop]->Media->LogicalPartition && blockio[loop]->Media->MediaPresent) {
      uint8_t cache[blockio[loop]->Media->BlockSize]; // Cache for drive header
      uint8_t cache2[blockio[loop]->Media->BlockSize]; // Cache for part header
      err = blockio[loop]->ReadBlocks(blockio[loop], blockio[loop]->Media->MediaId, 1, blockio[loop]->Media->BlockSize, cache);
      if (EFI_ERROR(err)) errexit("Broken drive\n");

      if (memcmp(efiheader, cache, 8)==0) { // Valid GPT drive
        int startlba = *((uint64_t *) (cache+0x48));

        err = blockio[loop]->ReadBlocks(blockio[loop], blockio[loop]->Media->MediaId, startlba, blockio[loop]->Media->BlockSize, cache);
        if (EFI_ERROR(err)) errexit("Broken drive\n");

        efi_partition_entry_t *parts = (void *) cache;

        for (unsigned int partloop=0;partloop<4;partloop++) {
          if (parts[loop].PartitionTypeGUID.Data1 == 0) continue;
          // Read first sector of the partition
          err = blockio[loop]->ReadBlocks(blockio[loop], blockio[loop]->Media->MediaId, parts[partloop].StartingLBA, blockio[loop]->Media->BlockSize, cache2);
          if (EFI_ERROR(err)) errexit("Broken drive\n");
          // Detect kfs header
          if (memcmp(kfs, cache2+3, 3)==0) return (struct ioandoffset) {blockio[loop], parts[partloop].StartingLBA, ((struct kfs_bootsec *) cache2)->highlightedfile};
        }
      };
    }
  }

  return (struct ioandoffset) {NULL, 0, 0};
}

void findfreepages(unsigned int *lenfreememret, struct memregion *freemem, void *map, unsigned int loops, unsigned int descriptorsize) {
  unsigned int lenfreemem = 0;

  // I kept trying to do all of it in this for loop instead of having the second line but it kept optimizing out map lmao
  for (unsigned int loop=0;loop < loops;loop++) {
    efi_memory_descriptor_t *desc = (void *) map + (loop * descriptorsize);

    if (desc->Type > 0 && desc->Type <= 7) {
      if (freemem != 0) {
        freemem[lenfreemem].base = desc->PhysicalStart;
        freemem[lenfreemem].size = desc->NumberOfPages*4096;
      }
      lenfreemem++;
    }
  }
  if (lenfreememret != 0) {
    *lenfreememret = lenfreemem;
  }
}

unsigned int ismemfree(unsigned int lenfree, struct memregion *mem, uint64_t base, uint64_t size) {
  // TODO add the ability to check over multiple entries
  for (unsigned int loop=0;loop < lenfree;loop++)
    if (mem[loop].base <= size && mem[loop].size > size) return 1;
  return 0;
}

struct elf64_ehdr {
  uint8_t  e_ident[16];   /* Magic number and other info */
  uint16_t e_type;        /* Object file type */
  uint16_t e_machine;     /* Architecture */
  uint32_t e_version;     /* Object file version */
  uint64_t e_entry;       /* Entry point virtual address */
  uint64_t e_phoff;       /* Program header table file offset */
  uint64_t e_shoff;       /* Section header table file offset */
  uint32_t e_flags;       /* Processor-specific flags */
  uint16_t e_ehsize;      /* ELF header size in bytes */
  uint16_t e_phentsize;   /* Program header table entry size */
  uint16_t e_phnum;       /* Program header table entry count */
  uint16_t e_shentsize;   /* Section header table entry size */
  uint16_t e_shnum;       /* Section header table entry count */
  uint16_t e_shstrndx;    /* Section header string table index */
} __attribute__((packed));

struct elf64_programheader {
  uint32_t p_type;
  uint32_t p_flags;
  uint64_t p_offset; // location of segment in file
  uint64_t p_vaddr; // segment virtual
  uint64_t p_paddr; // segment physical
  uint64_t p_filesz;
  uint64_t p_memsz; // size of segment
  uint64_t p_align;	// allignment
} __attribute__((packed));

uint64_t elfgetsize(void *file) {
  struct elf64_ehdr *header = file;
  struct elf64_programheader *segment = file + header->e_phoff;
  return segment->p_memsz;
}

uint64_t elfgetpos(void *file) {
  struct elf64_ehdr *header = file;
  struct elf64_programheader *segment = (struct elf64_programheader *) (header->e_phoff + file);
  return segment->p_offset;
}

int main(int argc, char **argv) {
  struct ioandoffset kfs = findkfs();
  if (kfs.disc == NULL) errexit("Cannot find KFS Partition\n");
  printf("kfs: %p, %i, %i\n", kfs.disc, kfs.lba, kfs.highlighted);

  char cache[512];
  kfs.disc->ReadBlocks(kfs.disc, kfs.disc->Media->MediaId, kfs.lba+kfs.highlighted, 512, &cache);

  struct kfs_file *kernelfile = (void *) cache;
  struct kfs_fileentry *entry = (void *) cache+74; // cc keeps turning sizeof(kfs_file) into 80 instead of 74

  unsigned long long kernelsize = 512*(entry->end - entry->start);
  printf("%i, %i, %u\n", entry->start, entry->end, entry->end - entry->start);

  char *kernelelf = malloc(kernelsize);
  if (kernelelf == 0) errexit("couldnt allocate space for kernel\n");
  kfs.disc->ReadBlocks(kfs.disc, kfs.disc->Media->MediaId, kfs.lba + entry->start, kernelsize, (void *) kernelelf);

  // klos wants to be loaded to directly after the first megabyte, it would be really fucking epic if we could put it there in actual memory, so lets see.
  uintn_t size = 0;
  uintn_t descriptorsize = sizeof(efi_memory_descriptor_t);
  uintn_t mapkey;
  // get memory map size
  efi_status_t err = BS->GetMemoryMap(&size, NULL, &mapkey, &descriptorsize, NULL);
  if (err != EFI_BUFFER_TOO_SMALL) errexit("Couldnt get UEFI map size\n");

  char map[size]; // no allocation, no memory map changes? So annoying, even posix-efi's example doesnt work because the size increases drastically after the first getmemorymap call
  // also ovmf for some reason leaves like no extra memory, sometimes there isnt even enough to allocate this lol

  // get memory map
  err = BS->GetMemoryMap(&size, (efi_memory_descriptor_t *) map, &mapkey, &descriptorsize, NULL);
  if (err == EFI_BUFFER_TOO_SMALL) errexit("EFI Map buffer too small\n");
  if (EFI_ERROR(err)) errexit("Couldnt get UEFI map\n");
  
  // I tried to optimize this manually by having (entrypoint:)'s and having lenfree as a signed integer and stuff but it was adding to the stack in the loop even with -O0 :sob:

  // Since we cant allocate memory anymore (to preserve memory map) we haved to use the stack
  unsigned int lenfree = 0;
  findfreepages(&lenfree, NULL, map, size / descriptorsize, descriptorsize);
  struct memregion freeregions[lenfree];
  findfreepages(&lenfree, (struct memregion *) freeregions, map, size / descriptorsize, descriptorsize);
  
  void *kernelentry = ((struct elf64_ehdr *) kernelelf)->e_entry;

  // get size of elf so we can find out if the right spot is free
  uint64_t elfsize = elfgetsize(kernelelf);
  register unsigned int debug = 0xff;
  // Find out if we can put the kernel in real memory
  if (ismemfree(lenfree, freeregions, 0x1000, elfsize + 0x4000)) { /* kernel then 4 pages */
    // Load kernel to memory
    memcpy(0x1000, kernelelf + elfgetpos(kernelelf), elfsize);
    // Create pagemap for kernel
    // Pagemap location

    err = BS->ExitBootServices(IM, mapkey);
    if (EFI_ERROR(err)) {
      errexit("ExitBootServices\n");
    }
    
    __attribute__((sysv_abi)) void (*kernel)(void *, void *, unsigned int) = kernelentry;
    kernel(0x1000, freeregions, lenfree);
  } else {
    // Load kernel to virtual memory

  }


  while (1) asm("hlt");
}