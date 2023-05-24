void main() { // btw this should NEVER return, thankyou for listening to my tedtalk.
  unsigned char *VGA = (unsigned char *) 0xB8000;
  unsigned char msg[] = "Hello World";
  for (int loop=0;loop!=13;loop++) {
    VGA[loop*2] = msg[loop];
    VGA[loop*2+1] = 7;
  }
  while (1) asm("hlt");
}