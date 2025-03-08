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

build: $(out) $(out)/main.$(kerneltarget).elf $(out)/kernel.elf $(out)/BOOTX64.efi $(out)/klos.img 
run: build qemu clean
debug: build qemudebug clean

$(out):
	mkdir -p $(out)

$(out)/main.$(kerneltarget).elf:
	nasm $(src)/kernel/arch/main.$(kerneltarget).S -f elf64 -o $(out)/main.$(kerneltarget).elf

#kernel compilation

$(out)/kernel.elf: $(kernelobjects)
	x86_64-elf-ld -T $(src)/kernel/linker.ld $(out)/main.$(kerneltarget).elf $^ -o $(out)/kernel.elf -pie
	x86_64-elf-objdump -S -M intel -D -m i386 out/kernel.elf > out/kernel.asm

$(kernelobjects): $(kernelcsources)

$(out)/%.o: $(src)/kernel/%.c
	x86_64-elf-gcc $(kargs) $< -o $@

$(out)/%.o: $(src)/kernel/*/%.c
	x86_64-elf-gcc $(kargs) $< -o $@

# bios assembly :raah:

$(out)/BOOTX64.efi:
	clang -fshort-wchar -fno-strict-aliasing -ffreestanding -fno-stack-protector -fno-stack-check -I. -I./posix-uefi/uefi -I/usr/include -I/usr/include/efi -I/usr/include/efi/protocol -I/usr/include/efi/x86_64 -D__x86_64__ -DHAVE_USE_MS_ABI -mno-red-zone --target=x86_64-pc-win32-coff -Wno-builtin-requires-header -Wno-incompatible-library-redeclaration -Wno-long-long \
	-c src/uefiboot.c -o out/uefiboot.o -O0
	lld -flavor link -subsystem:efi_application -nodefaultlib -dll -entry:uefi_init posix-uefi/uefi/*.o out/uefiboot.o -out:out/BOOTX64.EFI

# make the image

$(out)/klos.img:
# format kfs 1000 megabytes
	python3 kfs/format.py $(out)/klos.img 1000 0 $(out)/kernel.elf

# format the efi fs
#	mkfs.fat -C -F 32 $(out)/efi.img 20480
	truncate $(out)/efi.img -s 12M
	mformat -i $(out)/efi.img
	mmd -i $(out)/efi.img ::/EFI ::/EFI/BOOT ::/boot

# Copy limine to efi.img
	mcopy -i $(out)/efi.img out/BOOTX64.EFI ::/EFI/BOOT

# create the disc image with a efi and kfs partition
	truncate $(out)/image.img -s 1024M
	parted $(out)/image.img --script mklabel gpt
	parted $(out)/image.img --script mkpart primary 2M 12M
	parted $(out)/image.img --script mkpart primary 13M 1000M

# assemble the partitions
	dd if=$(out)/efi.img of=$(out)/image.img bs=1M seek=2 conv=notrunc
	dd if=$(out)/klos.img of=$(out)/image.img bs=1M seek=12 conv=notrunc
# testing
# sudo dd if=out/image.img of=/dev/sda

qemu:
	qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -D ./qemulog.txt -hda $(out)/image.img -d int -no-reboot -M memory-backend=foo.ram -object memory-backend-file,size=1G,id=foo.ram,mem-path=ram.bin,share=on,prealloc=on
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -hda $(out)/image.img -d int -no-reboot -monitor stdio -M memory-backend=foo.ram -object memory-backend-file,size=1G,id=foo.ram,mem-path=ram.bin,share=on,prealloc=on

clean:
	rm -rf $(out)