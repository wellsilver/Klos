#include <efi/efi.h>
#include <efi/efilib.h>

#define outb(port, data8) asm volatile ("outb")

EFI_STATUS EFIAPI efi_main (EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  InitializeLib(ImageHandle, SystemTable);

  UINTN g_memoryMapSize;
  UINTN memoryMapKey;
  UINTN g_memoryDescriptorSize;
  UINT32 memoryDescriptorVersion;
  UINTN g_memoryMapCount;
  EFI_PHYSICAL_ADDRESS g_memoryMap;

  ASSERT(SystemTable->BootServices->GetMemoryMap(&g_memoryMapSize, (EFI_MEMORY_DESCRIPTOR *) tmpMemoryMap, &memoryMapKey, &g_memoryDescriptorSize, &memoryDescriptorVersion) == EFI_BUFFER_TOO_SMALL);
  g_memoryMapSize += EFI_PAGE_SIZE;
  SystemTable->BootServices->AllocatePages(AllocateAnyPages, (EFI_MEMORY_TYPE)0x80000001, EFI_SIZE_TO_PAGES(g_memoryMapSize), (EFI_PHYSICAL_ADDRESS *) g_memoryMap);
  SystemTable->BootServices->GetMemoryMap(&g_memoryMapSize, (EFI_MEMORY_DESCRIPTOR *) &g_memoryMap, &memoryMapKey, &g_memoryDescriptorSize, &memoryDescriptorVersion);
  g_memoryMapCount = g_memoryMapSize / g_memoryDescriptorSize;
  SystemTable->BootServices->ExitBootServices(ImageHandle, memoryMapKey);

  

  while (1) {asm("hlt");}

  return EFI_SUCCESS;
}