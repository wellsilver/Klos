# build
all platforms: (made on debian linux)

there are submodules

```make run``` compiles then starts with qemu

needs ``nasm``, ``qemu-system-x86``, ``make``, ``truncate``, ``wget``

run (has apt, run as sudo) ``bash ./installtools.sh`` to install everything needed

### boot

kfs has the first 5 sectors free for bios boot (I hate UEFI) and is the full 

kernel loads into 0x10000 (or is mapped there, preferrably in real memory as its free for bios compat)

has a fully setup page map (that can be anywhere) where memory not free is marked as unwritable