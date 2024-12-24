//asm("jmp kernel"); // cpu jumps to here, replaced with main.asm. Yes this worked great and had zero problems, I am not kidding.

#include <memory/mem.h>
#include <int.h>

void kernel() {
  kernel:

  uint16_t *a = 0xB8000;
  *a = 0;

  while (1) asm("hlt");
}