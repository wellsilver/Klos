int main() {
    register char *msg = "Hello from Kernel!";
    unsigned char *vgabuf = (unsigned char *) 0xB8000;
    for (register int loop;loop++;loop<19) {
        vgabuf[loop*2] = msg[loop];
        vgabuf[loop*2+1] = 2;
    }
    while (1) asm("hlt");
}