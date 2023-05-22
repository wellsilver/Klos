"""
KFS DOC

- KFS
  - bootsector
    3 bytes reserved (jmp short x, nop)
    offset | description
    4  | char3 allways "kfs"
    7  | char12 disc name
    19 | uint8 version
    20 | uint8 how many sectors to skip to reach the first block
    21 | onwards is bootcode (or blank)
  - block
    A block is a kilobyte (1024 byte) large storage area
    - addressing blocks
      a blockaddr is a uint64_t which starts from 1, 0 is a magic number which means that the address does not exist
"""

class kfs:
  def __init__(self):
    self.buffer = bytearray("","utf-8")

  def save(self) -> bytearray:
    return self.buffer
  def save(self) -> str:
    return str(self.buffer)
  def load(self,data:bytearray):
    self.buffer = data
  def load(self,data:str):
    self.buffer = bytearray(data)
  
  """
  create a new kfs "drive" thats size sectors large 
  512*sectors to get size in bytes
  """
  def create(self,size:int):
    self.buffer = bytearray("","utf-8")
  def addfile(self,name:str,buffer:bytearray):
    pass
  def addfile(self,name:str,buffer:str):
    pass