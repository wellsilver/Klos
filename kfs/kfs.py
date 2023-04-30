def makeheader(type,permmisions:int,prevblock:int,nextblock:int,name:str) -> bytearray:
  ret = bytearray("",'ascii')
  ret+=permmisions.to_bytes(1,byteorder='little',signed=False)
  ret+=type.to_bytes(1,byteorder='little',signed=False)
  ret+=prevblock.to_bytes(8,byteorder='little',signed=False)
  ret+=nextblock.to_bytes(8,byteorder='little',signed=False)
  ret+=bytes(name,'ascii').ljust(24,b' ')
  return ret
def insertfile(writeto,file:bytes,name:str):
  blockptr=0
  rangeintofile=0
  for i in range(file): # assemble the lower kernel
    b=makeheader(1,10,blockptr,0,name)
    v = bytearray("",'ascii')
    while rangeintofile<=982*(blockptr+1):
      if rangeintofile >= len(file):
        break
      v.append(file[rangeintofile])
      rangeintofile+=1
    v = b+v # add the headers before the data
    v=v.ljust(1024,b'\0')
    file.write(v)
    blockptr+=1