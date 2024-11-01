# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil

kargs = -nostdlib -I $(src)/kernel -I $(src)/kernel/util -O0 -masm=intel -g -c

build: $(out) limine $(out)/main.x86.elf $(out)/util.o $(out)/disc.o $(out)/atapio.o $(out)/mem.o $(out)/main.o $(out)/kernel $(out)/kloslimineboot $(out)/biosboot.bin $(out)/klos.img 
run: build qemu clean
debug: build qemudebug clean

limine/limine:
	git clone https://github.com/limine-bootloader/limine --branch=v8.x-binary
	cd limine && make

$(out)/main.x86.elf:
	nasm $(src)/kernel/x86/main.x86.S -f elf64 -o $(out)/main.x86.elf

$(out)/util.o:
	x86_64-elf-gcc $(kargs) $(src)/kernel/util/util.c -o $(out)/util.o

$(out)/disc.o:
	x86_64-elf-gcc $(kargs) $(src)/kernel/disc/disc.c -o $(out)/disc.o

$(out)/atapio.o:
	x86_64-elf-gcc $(kargs) $(src)/kernel/disc/atapio.c -o $(out)/atapio.o

$(out)/mem.o:
	x86_64-elf-gcc $(kargs) $(src)/kernel/memory/mem.c -o $(out)/mem.o

$(out)/main.o:
	x86_64-elf-gcc $(kargs) $(src)/kernel/main.c -o $(out)/main.o

$(out)/kernel:
	x86_64-elf-ld $(src)/kernel/linker.ld $(out)/main.x86.elf $(out)/util.o $(out)/disc.o $(out)/atapio.o $(out)/mem.o $(out)/main.o -o $(out)/kernel.elf
	x86_64-elf-objdump -M intel -d out/kernel.elf > out/kernel.asm

$(out)/kloslimineboot:
	x86_64-elf-gcc -nostdlib $(src)/limineboot.c $(out)/util.o $(out)/atapio.o $(out)/disc.o -o $(out)/kloslimineboot -g -I limine -I $(src)/kernel/util -I $(src)/kernel -T $(src)/limineboot.ld -masm=intel -O0
	x86_64-elf-objdump -M intel -d out/kloslimineboot > out/kloslimineboot.S

$(out)/biosboot.bin:
	nasm $(src)/boot.x86.S -f bin -o $(out)/biosboot.bin
	truncate $(out)/biosboot.bin -s 1536

$(out):
	mkdir -p $(out)

$(out)/kernel.elf:
	nasm $(src)/kernel/x86/main.x86.S -f elf64 -o $(out)/main.x86.S.bin
	x86_64-elf-gcc -nostdlib -I $(src)/kernel -T $(src)/kernel/linker.ld $(out)/main.x86.S.bin $(src)/kernel/main.c -masm=intel -g -O0 -o $(out)/kernel.elf
	x86_64-elf-objdump -M intel -d out/kernel.elf > out/kernel.asm

$(out)/klos.img:
# format kfs 1000 megabytes
	python3 kfs/format.py $(out)/klos.img 1000 $(out)/biosboot.bin $(out)/kernel.elf

# format the efi fs
#	mkfs.fat -C -F 32 $(out)/efi.img 20480
	truncate $(out)/efi.img -s 12M
	mformat -i $(out)/efi.img
	mmd -i $(out)/efi.img ::/EFI ::/EFI/BOOT ::/boot ::/boot/limine

# Copy limine to efi.img
	mcopy -i $(out)/efi.img limine.conf limine/limine-bios.sys ::/boot/limine
	mcopy -i $(out)/efi.img $(out)/kloslimineboot ::/boot
	mcopy -i $(out)/efi.img limine/BOOTX64.EFI ::/EFI/BOOT
	mcopy -i $(out)/efi.img limine/BOOTIA32.EFI ::/EFI/BOOT

# create the disc image with a efi and kfs partition
	truncate $(out)/image.img -s 1024M
	parted $(out)/image.img --script mklabel gpt
	parted $(out)/image.img --script mkpart primary 2M 12M
	parted $(out)/image.img --script mkpart primary 13M 1000M

	./limine/limine bios-install $(out)/image.img

# assemble the partitions
	dd if=$(out)/efi.img of=$(out)/image.img bs=1M seek=2 conv=notrunc
	dd if=$(out)/klos.img of=$(out)/image.img bs=1M seek=12 conv=notrunc

qemu:
	qemu-system-x86_64 -D ./qemulog.txt -hda $(out)/image.img -m 4G -d int -no-reboot
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -hda $(out)/image.img -m 4G -d int -no-reboot

clean:
	rm -rf $(out)