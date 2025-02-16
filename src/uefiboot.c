// POSIX-UEFI

#include <uefi.h>
#include <kfs/kfs.h>

struct ioandoffset {
  efi_block_io_t disc;
  uint64_t lba;
};

struct ioandoffset findkfs() {
  efi_guid_t bioGuid = EFI_BLOCK_IO_PROTOCOL_GUID;
  efi_handle_t blockiohandles[24];
  efi_block_io_t *blockio[24];
  uintn_t handle_size = sizeof(blockiohandles);
  efi_status_t err = BS->LocateHandle(ByProtocol, &bioGuid, NULL, &handle_size, (void **) &blockiohandles);
  handle_size /= sizeof(blockiohandles[0]);
  if (EFI_ERROR(err) || handle_size == 0) {printf("No blockio\n");exit(-1);};

  for (unsigned int loop=0;loop<handle_size;loop++) {
    err = BS->HandleProtocol(blockiohandles[loop], &bioGuid, (void **) &blockio[loop]);
    if (EFI_ERROR(err)) {printf("Error blockio handle %i\n", loop);exit(-1);};
  }
  
  char *kfs = "kfs";
  // First search the logical partitions, it seems like computers will only create logical partition/fake drive things for the boot drive
  for (unsigned int loop=0;loop<handle_size;loop++) {
    if (blockio[loop]->Media->LogicalPartition) {
      uint8_t cache[blockio[loop]->Media->BlockSize];
      blockio[loop]->ReadBlocks(blockio[loop], blockio[loop]->Media->MediaId, 0, blockio[loop]->Media->BlockSize, &cache);
      if (memcmp(kfs, cache+3, 3)==0) return (struct ioandoffset) {blockio[loop], 0}; // found kfs!
    }
  }
}

int main(int argc, char **argv) {
  struct ioandoffset kfs = findkfs();


  while (1) sleep(1);
}