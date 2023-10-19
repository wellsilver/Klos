#define outb(port, data8) asm volatile ("outb")

void _main() {
  unsigned char *vga = (unsigned char *) 0xb8000;

  vga[1] = 15;
  vga[0] = 'h';
  vga[3] = 15;
  vga[2] = 'i';

  while (1) {asm("hlt");}
}