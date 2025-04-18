//asm("jmp kernel"); // cpu jumps to here, replaced with main.asm. Yes this worked great and had zero problems, I am not kidding.

#include <memory/mem.h>
#include <int.h>

void kernel(void *kernellocation, void *pagemap, struct memregion *freemem, uint lenfreemem) {
  

  while (1) asm("hlt");
}