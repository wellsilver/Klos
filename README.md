# build
all platforms: (made on wsl:debian)

```make run``` compiles then starts with qemu

needs ``nasm``, ``qemu-system-x86``, ``make``, ``truncate``, ``wget``

run (has apt, sudo) bintil_cross.sh to install crosscompile binutil

run (has apt, sudo) gcc_cross.sh to install crosscompile gcc

### boot

kfs has the first 5 sectors free for bios boot (I hate UEFI) and is the full 

kernel loads into 0x10000 all the bootloader needs to do is load it there

kernel stack grows from 0xFF00 to 0x0

Theres a table above 0xFF00 where 0xFFFF stores the type of memory map given, which via the native bootloader is 2=(e820)