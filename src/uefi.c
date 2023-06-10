#include <efi/efi.h>
#include <efi/efilib.h>

EFI_STATUS EFIAPI efi_main (EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  InitializeLib(ImageHandle, SystemTable);
  Print(L"Hello, world!\n");

  while (1);

  return EFI_SUCCESS;
}