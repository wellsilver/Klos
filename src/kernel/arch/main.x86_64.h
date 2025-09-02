#ifndef arch_main_x86_64_h
#define arch_main_x86_64_h
/*
The header file with the locations of the tss64 and idt64 setup by main.x86_64.s

global entry
global tss64
global idt64
global idtptr
*/

extern void *tss64;
extern void *idt64;
extern void *idtptr;

#endif