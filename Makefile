# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out

kernelcsources := $(shell find $(src)/kernel -name "*.c")
kernelobjects := $(patsubst %.c, out/%.o, $(notdir $(kernelcsources)))
kerneltarget := x86_64


cc = x86-elf-gcc

kargs = -I $(src)/kernel -I $(src)/kernel/util -nostdinc -nostdlib -Os -g -c -masm=intel -mcmodel=large -ffreestanding -fPIE

.PHONY: qemu qemudebug clean

build: $(out) limine/limine $(out)/main.$(kerneltarget).elf $(out)/kernel.bin $(out)/kloslimineboot $(out)/biosboot.bin $(out)/klos.img 
run: build qemu clean
debug: build qemudebug clean

limine/limine:
	git clone https://github.com/limine-bootloader/limine --branch=v8.x-binary
	cd limine && make

$(out):
	mkdir -p $(out)

$(out)/main.$(kerneltarget).elf:
	nasm $(src)/kernel/arch/main.$(kerneltarget).S -f elf64 -o $(out)/main.$(kerneltarget).elf

#kernel compilation

$(out)/kernel.bin: $(kernelobjects)
	x86_64-elf-ld -T $(src)/kernel/linker.ld $(out)/main.$(kerneltarget).elf $^ -o $(out)/kernel.bin 
	x86_64-elf-objdump -S -b binary -M intel -D -m i386 out/kernel.bin > out/kernel.asm

$(kernelobjects): $(kernelcsources)

$(out)/%.o: $(src)/kernel/%.c
	x86_64-elf-gcc $(kargs) $< -o $@

$(out)/%.o: $(src)/kernel/*/%.c
	x86_64-elf-gcc $(kargs) $< -o $@

# limine (bootloader) compilation

$(out)/kloslimineboot:
	x86_64-elf-gcc -nostdlib -mcmodel=kernel $(src)/limineboot.c $(kernelobjects) -o $(out)/kloslimineboot -g -I limine -I $(src)/kernel/util -I $(src)/kernel -T $(src)/limineboot.ld -masm=intel -O0 
	x86_64-elf-objdump -S -M intel -d out/kloslimineboot > out/kloslimineboot.S

# bios assembly :raah:

$(out)/biosboot.bin:
	nasm $(src)/boot.x86.S -f bin -o $(out)/biosboot.bin
	truncate $(out)/biosboot.bin -s 1536

# make the image

$(out)/klos.img:
# format kfs 1000 megabytes
	python3 kfs/format.py $(out)/klos.img 1000 $(out)/biosboot.bin $(out)/kernel.bin

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

# testing

qemu:
	qemu-system-x86_64 -D ./qemulog.txt -hda $(out)/image.img -m 2G -d mmu,int -no-reboot
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -hda $(out)/image.img -m 2G -d mmu,int -no-reboot -monitor stdio

clean:
	rm -rf $(out)