void _start() {
  asm("jmp kernel");
}

void kernel() {
  kernel:
  
  // clear the entire page, apparently it takes the whole thing?
  for (int loop=0;loop<4096;loop++) ((char *) 0xB8000)[loop] = 0;

  while (1) asm("hlt");
}