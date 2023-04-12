docs on usage stuff

# os
## userland


## underground
### errors
``"bootloader: disk err"``
bootloader cant read the second sector

### machine descriptor:
area in memory from ``0x00007E00 ~ 0x0007FFFF`` used to describe the machine, its ram usage, its disc, anything a driver may need, etc.

I made this up, and only klos does this.


### memory usage:
| start | end | size | desc |
| ----- | --- | ---- | --- |
| 0x00000000 | 0x000004FF |  | unusable |
| 0x00000500 | 0x00007BFF | 30kb | stack for the kernel |
| 0x00007BFF | 0x00007DFF | 512b | unusable, bootsector |
| 0x00007E00 | 0x0007FFFF | 480.5kb | kernel |