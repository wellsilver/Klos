#ifndef process_h
#define process_h

struct process {
  unsigned int id;
  
  struct {
    uint64_t null;
    struct {
      char _[8]; // put stuff here lol
    } entry[4];
    uint16_t length;
    uint64_t pointer;
  } gdt;

  void *allocated;
}

int current;
struct process *processes;

void process_init() {
  current = 0;
}

#endif