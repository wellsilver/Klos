extern void kernel() {
    unsigned char *VGA = (unsigned char *) 0xb8000;
    char msg[] = "Hello world!";
    for (int loop=0;loop<13;loop++) {
        VGA[loop*2] = msg[loop];
        VGA[(loop*2)+1] = 0x0f;
    }
    while (1) asm("hlt");
}