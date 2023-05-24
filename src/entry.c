void main() { // bootloader loads this file!!!!!!! This is meant to setup everything the kernel needs
  unsigned char *VGA = (unsigned char *) 0xB8000;
  unsigned char msg[] = "Hello World";
  for (int loop=0;loop!=12;loop++) {
    VGA[loop*2] = msg[loop];
    VGA[loop*2+1] = 7;
  }
  while (1) asm("hlt");
}