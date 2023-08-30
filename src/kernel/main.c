char *msg = "Hello world";

#define outb(port, data8) asm volatile ("outb")

#define SERIAL 0x3f8

int main() { // dont return
  outb(SERIAL,'w');
  outb(SERIAL,'o');
  outb(SERIAL,'r');
  outb(SERIAL,'k');
  outb(SERIAL,'s');
  
  while (1) asm("hlt");
}