docs on usage stuff

# os
## notes
use registers, kernel stack doesnt expand

## underground
### errors
``"check drive"``
bios said the drive failed to reset

### memory usage:
| start | end | size | desc |
| ----- | --- | ---- | --- |
| 0x00000000 | 0x000004FF |  | unusable |
| 0x00000500 | 0x00007BFF | 30kb | kernel stack |
| 0x00007BFF | 0x00010000 | 2.56kb | bootsector |
| 0x00010000 | 0x0007FFFF | ~458kb | kernel |