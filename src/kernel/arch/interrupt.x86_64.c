#include <int.h>
#include <arch/main.x86_64.h>

struct InterruptDescriptor {
  uint16_t offset_1;   // offset bits 0..15
  uint16_t selector;   // a code segment selector in GDT or LDT
  uint8_t  ist;        // bits 0..2 holds Interrupt Stack Table offset, rest of bits zero.
  uint8_t  attributes; // gate type, dpl, and p fields
  uint16_t offset_2;   // offset bits 16..31
  uint32_t offset_3;   // offset bits 32..63
  uint32_t zero;       // reserved
};

void idtsetgate(int gate, void *ptr, uint8_t flags) {
  struct InterruptDescriptor *desc = idt64;

  desc[gate].offset_1 = (uint64_t) ptr & 0xFFFF;
  desc[gate].selector = 0x8; // Code
  desc[gate].ist      = 0;
  desc[gate].attributes = flags;
  desc[gate].offset_2 = ((uint64_t)ptr >> 16) & 0xFFFF;
  desc[gate].offset_3 = ((uint64_t)ptr >> 32) & 0xFFFFFFFF;
  desc[gate].zero = 0;

  asm("lidt [%0]" : : "r" (idtptr));
}