char *msg = "Hello world";

#define outb(port, data8) asm volatile ("outb")

void _main() {
  
  while (1) asm("hlt");
}