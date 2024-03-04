# build
all platforms: (made on wsl:debian)

```make run``` compiles then starts with qemu

needs ``nasm``, ``qemu-system-x86``, ``make``, ``truncate``, ``wget``

run (has apt, sudo) bintil_cross.sh to install crosscompile binutil

run (has apt, sudo) gcc_cross.sh to install crosscompile gcc

### s

kfs has the first 5 sectors free for bios boot (I hate UEFI)

kernel loads into 0x10000 all the bootloader needs to do is load it there. no virtual memory or anything