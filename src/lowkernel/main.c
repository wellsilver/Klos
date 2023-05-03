int main() {
    register char *msg = "Hello from Kernel!";
    unsigned char *vgabuf = (unsigned char *) 0xB8000;
    vgabuf[0] = 'h';
    vgabuf[1] = 7;
    vgabuf[2] = 'i';
    vgabuf[3] = 7;
    while (1) asm("hlt");
}