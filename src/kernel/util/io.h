#ifndef ioh
#define ioh

uint8_t inb(uint16_t port) {
  uint8_t out;
  asm("inb %0, %1": "=a"(out) : "d"(port));
  
  return out;
}

void outb(uint16_t port, uint8_t a) {
  asm("outb %1, %0 " :: "a"(a), "d"(port));
}

#endif