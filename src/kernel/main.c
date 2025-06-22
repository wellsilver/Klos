//asm("jmp kernel"); // cpu jumps to here, replaced with main.asm. Yes this worked great and had zero problems, I am not kidding.

#include <memory/mem.h>
#include <int.h>

void crashandburn() {
  asm("mov rsp, 0xDEADBEEF" : : : "memory"); // asm isnt usually value like deadbeef.
  while (1) asm("hlt");
}

void kernel(void *kernellocation, struct memregion *freemem, uint lenfreemem) {
  int err = meminit(freemem, lenfreemem);
  if (err != 0)
  
  while (1) asm("hlt");
}