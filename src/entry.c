extern void entry() { // find sys/kernel in the fs and run it. this is called by the bootloader after entering long mode. fits in 1 sector.
    unsigned char *vga = 0xB8000;
    while (1) {
        vga[1] = 'h';
        vga[3] = 'i';
    }
}