#include <efi/efi.h>
#include <efi/efilib.h>

EFI_STATUS GetImageHandle(EFI_HANDLE* gImageHandle) {
  EFI_BOOT_SERVICES* bs = gBS;
  EFI_STATUS status;

  status = bs->HandleProtocol(
    gImageHandle,
    &gEfiLoadedImageProtocolGuid,
    (VOID**) gImageHandle
  );

  if (EFI_ERROR(status)) {
    // Handle error condition
    return status;
  }

  return EFI_SUCCESS;
}

EFI_STATUS ExitBootServices() {
  EFI_STATUS status;
  UINTN mapKey;
  EFI_MEMORY_DESCRIPTOR* memoryMap;
  UINTN mapSize;
  UINTN descriptorSize;
  EFI_BOOT_SERVICES* bs = gBS;
  EFI_HANDLE* gImageHandle;

  GetImageHandle(gImageHandle);

  // Get the required memory buffer size for the memory map
  mapSize = 0;
  status = bs->GetMemoryMap(&mapSize, memoryMap, &mapKey, &descriptorSize, NULL);
  if (status != EFI_BUFFER_TOO_SMALL) {
    // Handle error condition
    return status;
  }

  // Allocate memory for the memory map
  status = bs->AllocatePool(EfiLoaderData, mapSize, (void**)&memoryMap);
  if (EFI_ERROR(status)) {
    // Handle memory allocation failure
    return status;
  }

  // Get the memory map
  status = bs->GetMemoryMap(&mapSize, memoryMap, &mapKey, &descriptorSize, NULL);
  if (EFI_ERROR(status)) {
    // Handle error condition
    bs->FreePool(memoryMap);
    return status;
  }

  // Exit boot services
  status = bs->ExitBootServices(gImageHandle, mapKey);
  if (EFI_ERROR(status)) {
    // Handle error condition
    bs->FreePool(memoryMap);
    return status;
  }

  // Perform any additional post-exit tasks
  // ...

  // Free the memory map
  bs->FreePool(memoryMap);
}

EFI_STATUS EFIAPI efi_main (EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  InitializeLib(ImageHandle, SystemTable);
  Print(L"Hello, world!\n");

  while (1);

  return EFI_SUCCESS;
}