//asm(".org 0x00010000"); // done by LD

void _start() {
  asm("jmp kernel");
}


void kernel() {
  kernel:

  (*(char *) 0xB8000) = 'k';

  while (1) asm("hlt");
}