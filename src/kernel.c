extern void kernel() {
    unsigned char *VGA = (unsigned char *) 0xB8000;
    VGA[0] = 'h';
    while (1) {}
}