//asm("jmp kernel"); // cpu jumps to here, replaced with main.asm. Yes this worked great and had zero problems, I am not kidding.

#include <memory/mem.h>
#include <int.h>

void kernel(void *kernellocation, struct memregion *freemem, uint lenfreemem) {
  // Test pagefaulthandler
  *((char *) 0) = 'a'; 
  //meminit(freemem, lenfreemem);

  while (1) asm("hlt");
}