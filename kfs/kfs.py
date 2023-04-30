def makeheader(type,permmisions:int,prevblock:int,nextblock:int,name:str) -> bytearray:
  ret = bytearray("",'ascii')
  ret+=permmisions.to_bytes(1,byteorder='little',signed=False)
  ret+=type.to_bytes(1,byteorder='little',signed=False)
  ret+=prevblock.to_bytes(8,byteorder='little',signed=False)
  ret+=nextblock.to_bytes(8,byteorder='little',signed=False)
  ret+=bytes(name,'ascii').ljust(24,b' ')
  return ret
def insertfile(writeto,file:bytearray):
  # the first step to adding the file is splitting it into 982 byte chunks, which is the size of a block (ignoring header) in kfs...
  f, r = divmod(len(file),982)
  f+=1 # ignore r, we just want to get the size in blocks of lowkernel.bin rounding up.

  blockptr=0
  rangeintofile=0
  for i in range(f): # assemble the lower kernel
    b=makeheader(1,10,blockptr,0,"lowkernel")
    v = bytearray("",'ascii')
    while rangeintofile<=982*blockptr:
      if file[rangeintofile] == None:
        break
      v.append(file[rangeintofile])
      rangeintofile+=1
    v = v+b
    v=v.ljust(1024,b' ')
    file.write(v)
    blockptr+=1
