char *msg = "Hello world";

#define outb(port, data8) asm volatile ("outb")

void main() { // dont return
  
  
  while (1) asm("hlt");
}