import sys

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

