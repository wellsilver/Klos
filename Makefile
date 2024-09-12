# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil

build: $(out) limine $(out)/kernel.elf $(out)/klos.img 
run: $(out) limine $(out)/kernel.elf $(out)/klos.img qemu clean
debug: build qemudebug clean

limine:
	git clone https://github.com/limine-bootloader/limine --branch=v8.x-binary
	cd limine && make

$(out):
	mkdir -p $(out)

$(out)/kernel.elf:
	nasm $(src)/kernel/x86/main.x86.S -f elf64 -o $(out)/main.x86.S.bin
	x86_64-elf-gcc -nostdlib -I $(src)/kernel -T $(src)/kernel/linker.ld $(out)/main.x86.S.bin $(src)/kernel/main.c -masm=intel -g -O0 -o $(out)/kernel.elf
	x86_64-elf-objdump -M intel -d out/kernel.elf > out/kernel.asm

$(out)/klos.img:
# format kfs 1000 megabytes
	python3 kfs/format.py $(out)/klos.img 1000 /dev/null $(out)/kernel.elf

# format the efi fs
	mkfs.fat -C -F 16 $(out)/efi.img 20480

# assemble the efi and kfs images into one
	truncate $(out)/image.img -s 1024M
	parted $(out)/image.img --script mklabel gpt
	parted $(out)/image.img --script mkpart primary 2M 11M
	parted $(out)/image.img --script mkpart primary 12M 1000M

	parted $(out)/image.img --script p
	dd if=$(out)/efi.img of=$(out)/image.img bs=1M seek=2 conv=notrunc
	dd if=$(out)/klos.img of=$(out)/image.img bs=1M seek=12 conv=notrunc
	parted $(out)/image.img --script p

qemu:
	qemu-system-x86_64 -D ./qemulog.txt -drive file=$(out)/image.img -m 4G -d int -no-reboot
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -drive file=$(out)/image.img -m 4G -d int -no-reboot

clean:
	rm -rf $(out)