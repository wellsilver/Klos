# python script to manage the image

"""
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
"""

def makeheader(type,permmisions:int,prevblock:int,nextblock:int,name:str) -> bytearray:
  ret = bytearray("",'ascii')
  ret+=permmisions.to_bytes(1,byteorder='little',signed=False)
  ret+=type.to_bytes(1,byteorder='little',signed=False)
  ret+=prevblock.to_bytes(8,byteorder='little',signed=False)
  ret+=nextblock.to_bytes(8,byteorder='little',signed=False)
  ret+=bytes(name,'ascii').ljust(24,b' ')
  return ret

file = open("out/klos.img","wb")

f = open("out/bootloader.bin","rb")
bootloader = f.read()
f.close()

f = open("out/entry.bin","rb")
entry = f.read()
f.close()

f = open("out/lowkernel.bin","rb")
lowkernel = f.read()
f.close()

# THE BOOTLOADER HAS BOOTHEADERS&KFSSTUFF IN IT
file.write(bootloader) # write the bootloader to the image
file.write(entry.ljust(512,b'\0')) # write the kernel loader into memory

# setup root folder
v = bytearray("",'ascii')
v+=makeheader(2,10,0,0,"/root")
v+=(1).to_bytes(length=8,byteorder='little',signed=False) # pointer to kernel

file.write(v.ljust(1024,b'\0')) # create the "/root" folder

# entry is the kfs driver, its where the one sector we skip is. It loads the (lower) kernel as if its a file (hiddenfile "lowkernel")

# the first step to adding the file is splitting it into 982 byte chunks, which is the size of a block (ignoring header) in kfs...
f, r = divmod(len(lowkernel),982)
f+=1 # ignore r, we just want to get the size in blocks of lowkernel.bin rounding up.

blockptr=0
rangeintofile=0
for i in range(f): # assemble the lower kernel
  b=makeheader(1,10,blockptr,0,"lowkernel")
  v = bytearray("",'ascii')
  while rangeintofile<=982*(blockptr+1):
    if rangeintofile >= len(lowkernel):
      break
    v.append(lowkernel[rangeintofile])
    rangeintofile+=1
  v = b+v # add the headers before the data
  v=v.ljust(1024,b'\0')
  file.write(v)
  blockptr+=1

file.close()