keep in sync with github/wellsilver/kfs

# kfs

big fancy tree

little endian

simple (hopefully)

btw dont trust the tables in here, trust the structures in ``kfs.h`` lol

## overview
LBA
| start | end | desc |
| ----- | ----- | - |
| 1 | 5 | 5 sectors of 2.56 kilobytes for bootloader |
| 6 | 6 | fs extender |
| 7 | 7 | "/" or first folder |
| 8 | 10| reserved |
| 11 | ? | data |

a driver would be keeping the first 10 sectors in memory

### fs extender
this is for extending the fs past its actual hard drive

like an entry in here would say that "sectors" 0-500 is the hard drive at sata:0

another entry would say that "sectors" 501-600 is a specific file on a ftp server

each entry is 64 bytes long leaving 8 entries

empty entrys have the first byte as zero

if blank set first entry type enum to 254

#### entry
| start | end | type | desc |
| ----- | --- | ---- | ---- |
| 0 | 0 | u8  | type enum   |
| 1 | 8 | u64 | start sector|
| 9 | 17| u64 | end sector  |
| 11| 63| ... | type specific data |

#### type enum
| num | desc |
| --- | ---- |
| 0   | empty |
| 1   | drive |
| 254 | blank |
..


### folders

folders contain entrys that point to other files or folders

#### type enum
| num | desc |
| --- | ---- |
| 0   | empty |
| 1   | descriptor |
| 2   | filedesc  |
| 3   | filedata  |
| 4   | filename  |
| 5   | folder|

#### entry
all entrys are 32 bytes large

all
| start | end | type | desc |
| ----- | --- | ---- | ---- |
| 0     | 0   | u8   | type enum |

descriptor - folders cant be of a finite size, this will point to the previous sector for the folder (or 0 if nil) and the next sector of the folder (or 0 if nil) this should be the first entry
| start | end | type | desc |
| ----- | --- | ---- | ---- |
| 1     | 8   | u64  | previous sector |
| 9     | 17  | u64  | next sector |
| 18    | 31  | ?    | unused |

filedata - gives a range of sectors associated with a file through a fileID
| start | end | type | desc |
| ----- | --- | ---- | ---- |
| 1     | 8   | u64  | first sector in range |
| 9     | 17  | u64  | last sector in range  |
| 18    | 20  | u16  | fileID |
| 21    | 28  | u64  | the number of ``filedata`` entrys for this file before this entry |
| 25    | 31  | ?    | unused |

file
| start | end | type | desc |
| ----- | --- | ---- | ---- |
| 1     | 2   | u16  | fileID, only needs to be unique inside a single directory |
| 3     | 3   | u8   | encryption method |
| 4     | 4   | u8   | compression method|
| 5     | 13  | u64  | epoch of creation |
| 14    | 22  | u64  | epoch of last modification |
| 14    | 31  | ?    | unsued |

filename
| start | end | type | desc |
| ----- | --- | ---- | ---- |
| 1     | 2   | u16  | fileID |
| 4     | 31  | str(28) | file name |