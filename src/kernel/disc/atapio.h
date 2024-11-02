#ifndef atapio_h
#define atapio_h

uint atapio_read48(uint drive, uint64_t lba, uint sectors, void *ptr);
struct drive atapio_hasdrive();

#endif