// POSIX-UEFI

#include <uefi.h>
#include <kfs/kfs.h>

int main(int argc, char **argv) {
  efi_guid_t bioGuid = EFI_BLOCK_IO_PROTOCOL_GUID;
  efi_handle_t blockiohandles[24];
  efi_block_io_t *blockio[24];
  uintn_t handle_size = sizeof(blockiohandles);
  efi_status_t err = BS->LocateHandle(ByProtocol, &bioGuid, NULL, &handle_size, &blockiohandles);
  handle_size /= sizeof(blockiohandles[0]);
  if (EFI_ERROR(err) || handle_size == 0) {printf("No blockio\n");sleep(2);return 0;};

  printf("Present - FLAG - POINTER          - MEDIA ID\n");
  for (unsigned int loop=0;loop<handle_size;loop++) {
    err = BS->HandleProtocol(blockiohandles[loop], &bioGuid, &blockio[loop]);
    if (EFI_ERROR(err)) {printf("Error blockio handle %i\n", loop); break;};
    // Present
    if (blockio[loop]->Media->MediaPresent == 1) printf("Yes     - ");
    else printf("No      - ");
    // Flags
    if (blockio[loop]->Media->RemovableMedia == 1) putchar('R');
    else putchar(' ');
    if (blockio[loop]->Media->LogicalPartition == 1) putchar('L');
    else putchar(' ');
    if (blockio[loop]->Media->ReadOnly == 1) putchar('r');
    else putchar(' ');
    if (blockio[loop]->Media->WriteCaching == 1) putchar('w');
    else putchar(' ');

    printf(" - %p - %i\n", blockiohandles[loop], blockio[loop]->Media->MediaId);
  }
  
  while (1);
}