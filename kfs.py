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
    bootfile = open(i,"r")
  
  if i == "-f":
    files.append((sys.argv[dist+1], open(sys.argv[dist+2],"r") ))
    dist+=1

  if i == "-s":
    dist+=1
    i = sys.argv[dist]

    if i.endswith("M"):
      i = i.replace("M","")
      size = int(i) * 1000000
  
  dist+=1