#include <int.h>

void strreverse(char* begin, char* end) {
  char aux;

  while(end>begin)
    aux=*end, *end--=*begin, *begin++=aux;
}

// int to ascii (base-10)
void itoa(unsigned int n, char *str, int bufsize) {
  int loop = 0;

  for (;loop < bufsize;loop++) {
    // get first digit in n
    str[loop] = '0' + (n % 10);
    n -= (n % 10); // make the last digit in n 0 so we can divide it by 10 to remove it
    if (n==0) break; // if this is the last digit it might be zero
    n /= 10; // remove the last digit in n
  }
  
  strreverse(str, str+loop); // error here maybe, no checking if exceeds bufsize
}

// ascii to int
int atoi(char *str) {
  
}

uint8_t inb(uint16_t port) {
  uint8_t out;
  asm("inb %0, %1": "=a"(out) : "d"(port));
  
  return out;
}

void outb(uint16_t port, uint8_t a) {
  asm("outb %1, %0" : : "a"(a), "d"(port));
}

uint16_t inw(uint16_t port) {
  uint16_t out;
  asm("inw %0, %1": "=a"(out) : "d"(port));
  
  return out;
}

void outw(uint16_t port, uint16_t a) {
  asm("outw %1, %0 " : : "a"(a), "d"(port));
}