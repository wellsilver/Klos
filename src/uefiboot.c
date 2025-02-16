// POSIX-UEFI

#include <uefi.h>
#include <kfs/kfs.h>

efi_block_io_t findkfs() {
  efi_guid_t bioGuid = EFI_BLOCK_IO_PROTOCOL_GUID;
  efi_handle_t blockiohandles[24];
  efi_block_io_t *blockio[24];
  uintn_t handle_size = sizeof(blockiohandles);
  efi_status_t err = BS->LocateHandle(ByProtocol, &bioGuid, NULL, &handle_size, &blockiohandles);
  handle_size /= sizeof(blockiohandles[0]);
  if (EFI_ERROR(err) || handle_size == 0) {printf("No blockio\n");exit(-1);};

  for (unsigned int loop=0;loop<handle_size;loop++) {
    err = BS->HandleProtocol(blockiohandles[loop], &bioGuid, &blockio[loop]);
    if (EFI_ERROR(err)) {printf("Error blockio handle %i\n", loop);break;};
  }
  // First search partitions, it seems like computers will only create logical partition/fake drive things for the boot drive
  for (unsigned int loop=0;loop<handle_size;loop++) {
    
  }
}

int main(int argc, char **argv) {
  efi_block_io_t kfs = findkfs();

  while (1) sleep(1);
}