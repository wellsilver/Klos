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

int main(int argc, char **argv) {
  struct ioandoffset kfs = findkfs();
  if (kfs.disc == NULL) errexit("Cannot find KFS Partition\n");
  printf("kfs: %p, %i, %i\n", kfs.disc, kfs.lba, kfs.highlighted);
  while (1) sleep(1);
}