import sys
import time

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
    files.append((sys.argv[dist+1], open(sys.argv[dist+2],"rb") ))
    dist+=1

  if i == "-s":
    dist+=1
    i = sys.argv[dist]

    i = i.replace("M","")
    size = int(i) * 1000000
  dist+=1

if bootfile:
  bootsec = bootfile.read().ljust(512 * 5,b'\0')
else:
  bootsec = b"\0\0\0kfs\0".ljust(512 * 5,b'\0')

extender = b'\xac'.ljust(512, b'\0') # blank

folder = b'\1'.ljust(32,b'\0') # fill in descriptor

data = b''

id = 1
for i in files:
  # add the first file descriptor
  folder += ((2).to_bytes(length=1,byteorder='little') + id.to_bytes(length=2,byteorder='little') + b'\0\0' + int(time.time()).to_bytes(length=8,byteorder='little') + int(time.time()).to_bytes(length=8,byteorder='little')).ljust(32,b'\0')
  # add the file name
  folder += ((4).to_bytes(length=1,byteorder='little') + id.to_bytes(length=2,byteorder='little') + i[:28]).ljust(32,b'\0')
