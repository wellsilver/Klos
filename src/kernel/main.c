char *msg = "Hello world";

int main() { // dont return
  unsigned char *VGA = (unsigned char *) 0xB8000;
    for (int loop=0;loop<30;loop++) {
      VGA[loop*2] = msg[loop];
      VGA[(loop*2)+1] = 0x0f;
    }
  while (1) asm("hlt");
}