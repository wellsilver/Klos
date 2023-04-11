extern void kernel() {
    unsigned char *VGA = (unsigned char *) 0xb8000;
    VGA[0] = 'h';
    VGA[1] = 1;
    VGA[2] = 'i';
    VGA[3] = 1;
    while (1) asm("hlt");
}