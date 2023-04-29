extern void entry() { // find sys/kernel in the fs and run it. this is called by the bootloader after entering long mode. fits in 1 sector.
    unsigned char *vga = (unsigned char *) 0xB8000;
    while (1) {
        vga[0] = 'h';
        vga[1] = 1;
        vga[2] = 'i';
        vga[3] = 1;
    }
}