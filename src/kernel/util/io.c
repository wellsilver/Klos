#ifndef ioh
#define ioh

#include "int.h"

uint8_t inb(uint16_t port) {
  uint8_t out;
  asm("inb %0, %1": "=a"(out) : "d"(port));
  
  return out;
}

void outb(uint16_t port, uint8_t a) {
  asm("outb %1, %0" : : "a"(a), "d"(port));
}

uint16_t inw(uint16_t port) {
  uint16_t out;
  asm("inw %0, %1": "=a"(out) : "d"(port));
  
  return out;
}

void outw(uint16_t port, uint16_t a) {
  asm("outw %1, %0 " : : "a"(a), "d"(port));
}

#endif