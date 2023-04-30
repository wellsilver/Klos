all integers are little endian.

bootsector:
  3 bytes reserved (jmp short x, nop)
  offset | description
  4  | char3 allways "kfs"
  7  | uint64 (8 bytes large) how many sectors the disk holds
  15 | uint8 how large a block is in sectors
  16 | uint8 usability; 1 = readonly, 2 = normal, 3 = scanrecommended
  17 | uint8 version
  18 | uint8 how many sectors to skip to reach the first block
  19 | char12 disc name
  32 | onwards is bootcode (or blank)

block:
  file:
    offset | description
    0 | uint8 permmisions: 0 = DONTUSE, 1 = unwritable, 2 = hidden (OS Reserved), 10 = public, rest are for any usage (users, eg)
    1 | uint8 type: allways 1, means that this is a file
    2 | uint64 previous ptr: this points to the previous block that involves the file or 0, Pointers start from the first block
    11| uint64 next ptr: this points to the next block that involves the file or 0, Pointers start from the first block
    20| char24 name: The name of the file
  the rest of the block is the file. If the file ends before the block, it ends with EOF, if it ends after the block, assign a new block, and change next ptr to the new block, and start writing there
  directory:
    0 | uint8 permmisions: 0 = DONTUSE, 1 = unwritable, 2 = hidden (OS Reserved), 10 = public, rest are for any usage (users, eg)
    1 | uint8 type: allways 2, means that this is a directory
    2 | uint64 previous ptr: this points to the previous block that involves the directory or 0, Pointers start from the first block
    11| uint64 next ptr: this points to the next block that involves the directory or 0, Pointers start from the first block
    20| char24 name: The name of the directory
  the rest of the block is entrys. which are 8 byte (uint64) pointers to the first block of the file/directory
  directory entry:
    0 | uint64 ptr: pointer
  if there is no more space for entrys, allocate a new block, setup the header, and put entrys. rinse and repeat.
  if the entrys stop before the block, place a 0.
note that the first block should be a directory named "/root" which is the first directory. remember to truncate the string to 24 characters