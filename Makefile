# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil

build: $(out) $(out)/kernel.bin $(out)/klos.img 
run: $(out) $(out)/kernel.bin $(out)/klos.img qemu clean
debug: build qemudebug clean

$(out):
	mkdir -p $(out)

$(out)/kernel.bin:
	nasm $(src)/kernel/x86/main.x86.S -f elf64 -o $(out)/main.x86.S.bin
	x86_64-elf-gcc -nostdlib -I $(src)/kernel -T $(src)/kernel/linker.ld $(out)/main.x86.S.bin $(src)/kernel/main.c -masm=intel -g -O0 -o $(out)/kernel.elf
	x86_64-elf-objdump -M intel -d out/kernel.elf > out/kernel.asm

$(out)/klos.img:
	truncate $(out)/disc.img -s 1024M
	truncate $(out)/efi.img -s 24M
	parted $(out)/disc.img --script mklabel gpt
# EFI
	parted $(out)/disc.img --script mkpart logical FAT32 0 20M
# KFS
	parted $(out)/disc.img --script mkpart logical 20M 100%
# format the kfs fs 1000 megabytes
	python3 kfs/format.py $(out)/klos.img 1000 /dev/null $(out)/kernel.elf
	
	
qemu:
	qemu-system-x86_64 -D ./qemulog.txt -drive file=$(out)/disc.img -m 4G -d int -no-reboot
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -drive file=$(out)/disc.img -m 4G -d int -no-reboot

clean:
	rm -rf $(out)