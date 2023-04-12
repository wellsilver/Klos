docs on usage stuff

# os

strictly 64 bits only. The system will not start without having a 64 bit CPU

## userland


## underground
### errors
``"bootloader: disk err"``
bootloader cant read the second sector

### memory usage:
| start | end | size | desc |
| ----- | --- | ---- | --- |
| 0x00000000 | 0x000004FF |  | unusable |
| 0x00000500 | 0x00007BFF | almost 29kb | the kernel's stack |
| 0x00007BFF | 0x00007DFF | 512b | unusable, bootsector |
| 0x00007E00 | 0x0007FFFF | 480.5kb | usable (for FS?) |
| 0x00080000 | 0x000FFFFF | | unusable, bios & vga & stuff |
| 0x00100000 | .......... | ? | needs to be scanned for usability |