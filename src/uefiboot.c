// POSIX-UEFI

#include <uefi.h>
#include <kfs/kfs.h>

int main(int argc, char **argv) {
  efi_guid_t bioGuid = EFI_BLOCK_IO_PROTOCOL_GUID;
  efi_block_io_t *blockiohandles[24];
  uintn_t handle_size = sizeof(blockiohandles);
  efi_status_t err = BS->LocateHandle(ByProtocol, &bioGuid, NULL, &handle_size, (efi_handle_t*) &blockiohandles);
  if (EFI_ERROR(err)) {printf("No blockio\n");sleep(2);return 0;};
  handle_size /= sizeof(blockiohandles[0]);

  for (unsigned int loop=0;loop<handle_size;loop++) {
    if (!blockiohandles[loop]->Media->LogicalPartition) printf("Drive ");
    else printf("Part  ");
    printf("%p, %i\n", blockiohandles[loop], blockiohandles[loop]->Media->MediaId);
  }
  
  
  while (1);
}