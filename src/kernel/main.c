char *msg = "Hello world!";

int main() { // btw this should NEVER return, thankyou for listening to my tedtalk.
  unsigned char *vga = (unsigned char *) 0xB8000;
  for (int loop=0;msg[loop]!=0;loop++) { // loop until null terminator
    vga[loop * 2] = msg[loop];
    vga[loop * 2 + 1] = 7; // white
  }
  while (1) asm("hlt");
}