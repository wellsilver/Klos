void kmain() {
    unsigned char *vga = (unsigned char *) 0xB8000;
    vga[0] = 'h';
    vga[1] = 7;
    vga[2] = 'i';
    vga[3] = 7;
    while (1) asm("hlt");
}