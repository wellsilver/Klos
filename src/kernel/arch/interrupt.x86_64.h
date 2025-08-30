#ifndef interrupt_x86_64_h
#define interrupt_x86_64_h

#include <int.h>
void idtsetgate(int gate, void *ptr, uint8_t flags);

#endif