char *msg = "Hello world";

#define outb(port, data8) asm volatile ("outb")

void _main() {
  outb(0,0);
  
  while (1) asm("hlt");
}