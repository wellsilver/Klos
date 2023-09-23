import sys
import time
import io

files = []
bootfile = None
size = 0

dist = 0

while dist < len(sys.argv):
  i = sys.argv[dist]
  if i == "-boot":
    dist+=1
    i = sys.argv[dist]
    bootfile = open(i,"rb")
  
  if i == "-f":
    files.append((bytes(sys.argv[dist+1],encoding='utf-8'), open(sys.argv[dist+2],"rb") ))
    dist+=1

  if i == "-s":
    dist+=1
    i = sys.argv[dist]

    i = i.replace("M","")
    size = int(i) * 1000000
  
  if i == "-o":
    dist+=1
    out = open(sys.argv[dist],"wb")
  
  dist+=1

try:
  _ = out
except:
  print("did not set -o")
  quit()

if bootfile:
  bootsec = bootfile.read().ljust(512 * 5,b'\0')
else:
  bootsec = b"\0\0\0kfs\0".ljust(512 * 5,b'\0')

extender = (254).to_bytes(byteorder='little').ljust(512, b'\0') # blank

folder = b'\1'.ljust(32,b'\0') # fill in descriptor

data = b''

sectordist = 0
sectors = dict.fromkeys(range(0, divmod(size,512)[0]))
for i in sectors:
  sectors[i] = [None, 0] # which file, and sector in the file

id = 0
for i in files:
  id+=1
  # add the first file descriptor
  folder += ((2).to_bytes(length=1,byteorder='little') + id.to_bytes(length=2,byteorder='little') + b'\0\0' + int(time.time()).to_bytes(length=8,byteorder='little') + int(time.time()).to_bytes(length=8,byteorder='little')).ljust(32,b'\0')
  # add the file name
  folder += ( (4).to_bytes(length=1,byteorder='little') + id.to_bytes(length=2,byteorder='little') + i[0][:28] ).ljust(32,b'\0')
  # check sector availability and add file descriptor file data added later to not overload memory
  fl = len(i[1].read())
  fsize = (fl // 512) + 1 # size in sectors we need to allocate
  i[1].seek(0)
  for v in range(sectordist,fsize):
    sectors[v] = [i[1], v-sectordist]
  
  folder += ( (3).to_bytes(length=1,byteorder='little') + (sectordist+11).to_bytes(length=8,byteorder='little') + ((sectordist+fsize)+11).to_bytes(length=8,byteorder='little') + id.to_bytes(length=2,byteorder='little')).ljust(32,b'\0')


out.write(bootsec + extender + folder + b''.ljust(512 * 2, b'\0'))
# ^ ignore typecheck err

# we've written the first 10 sectors, time to handle files

for i in sectors:
  i = sectors[i]
  if i[0] == None:
    break
  i[0].seek(i[1]*512)
  out.write(i[0].read())
# whats with all the false typechecker errors?

out.close()