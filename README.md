# build
all platforms: (made on wsl:debian)

```sudo make run```  starts with qemu

needs ``nasm``, ``qemu-system-x86_64``, ``make``, ``gcc``, ``cat``, ``truncate``, ``objcopy``, ``wget``

should work on all modern 64 bit computers

run make with sudo

installs x86_64-elf toolchain and downloads prerequisites with apt if doesnt exist
