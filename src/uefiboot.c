// POSIX-UEFI

#include <uefi.h>
#include <kfs/kfs.h>

int main(int argc, char **argv) {
  efi_guid_t blockguid = EFI_BLOCK_IO_PROTOCOL_GUID;
  efi_block_io_t *blockio;
  efi_status_t err = BS->LocateProtocol(&blockguid, NULL, (void**) &blockio);
  if (EFI_ERROR(err)) {printf("No blockio\n");sleep(2);return 0;};
  
  blockio->ReadBlocks(blockio, 0, 0, 0, 0);

  while (1);
}