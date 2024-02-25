#ifndef disc_h
#define disc_h

/*
list of dv opts here: (for drive.getopt/drive.setopt)

list of fs opts here: (for fs.getopt/fs.setopt)

*/

// every storage device in the system
struct drive {
  void *data;
  void (*readsector)(int sector);
  void (*writesector)(int sector,char *sector);
  void *(*getopt)(char *name);
  void (*setopt)(char *name,void *arg);
} *drives;

struct fs {
  struct drive *m;
  unsigned long long startsector;
  unsigned long long endsector;
  void *(*getopt)(char *name);
  void (*setopt)(char *name,void *arg);
  void (*readfile_range)(char *path);
}

void add_drive() {

}

#endif