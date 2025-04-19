
src  = src
out  = out
asmc = nasm
CC   = x86_64-elf-gcc

build: $(out)/klos.img
run: build qemu
debug: build qemudebug

all: run

### KERNEL COMPILATION
#
#

kernelcsources := $(shell find $(src)/kernel -name "*.c")
kernelobjects := $(patsubst %.c, out/%.o, $(notdir $(kernelcsources)))
kerneltarget := x86_64

kernelargs = -I $(src)/kernel -I $(src)/kernel/util -nostdinc -nostdlib -Os -g -c -masm=intel -mcmodel=large -ffreestanding

$(out)/main.$(kerneltarget).elf: $(src)/kernel/arch/main.$(kerneltarget).S | $(out)
	nasm $< -f elf64 -o $(out)/main.$(kerneltarget).elf

$(out)/kernel.elf: $(kernelobjects) $(out)/main.$(kerneltarget).elf | $(out)
	x86_64-elf-ld -T $(src)/kernel/linker.ld $^ -o $(out)/kernel.elf
	x86_64-elf-objdump -S -M intel -D -m i386 out/kernel.elf > out/kernel.asm

$(out)/%.o: $(src)/kernel/%.c | $(out)
	$(CC) $(kernelargs) $< -o $@

$(out)/%.o: $(src)/kernel/*/%.c | $(out)
	$(CC) $(kernelargs) $< -o $@

### BOOTLOADERS
#
#

# EFI (posix-efi)
$(out)/BOOTX64.efi: $(src)/uefiboot.c | $(out)
	clang -fshort-wchar -fno-strict-aliasing -ffreestanding -fno-stack-protector -fno-stack-check -I. -I./posix-uefi/uefi -I/usr/include -I/usr/include/efi -I/usr/include/efi/protocol -I/usr/include/efi/x86_64 -D__x86_64__ -DHAVE_USE_MS_ABI -mno-red-zone --target=x86_64-pc-win32-coff -Wno-builtin-requires-header -Wno-incompatible-library-redeclaration -Wno-long-long \
	-c $^ -o out/uefiboot.o -O0
	lld -flavor link -subsystem:efi_application -nodefaultlib -dll -entry:uefi_init posix-uefi/uefi/*.o $(out)/uefiboot.o -out:$(out)/BOOTX64.EFI

### DISK IMAGE
#
#

$(out)/klos.img: $(out)/BOOTX64.efi $(out)/kernel.elf | $(out)
# format kfs 1000 megabytes
	python3 kfs/format.py $(out)/kfs.img 1000 0 $(out)/kernel.elf

# format the efi fs
#	mkfs.fat -C -F 32 $(out)/efi.img 20480
	truncate $(out)/efi.img -s 12M
	mformat -i $(out)/efi.img
	mmd -i $(out)/efi.img ::/EFI ::/EFI/BOOT ::/boot

# Copy limine to efi.img
	mcopy -i $(out)/efi.img $(out)/BOOTX64.EFI ::/EFI/BOOT

# create the disc image with a efi and kfs partition
	truncate $(out)/klos.img -s 1024M
	parted $(out)/klos.img --script mklabel gpt
	parted $(out)/klos.img --script mkpart primary 2M 12M
	parted $(out)/klos.img --script mkpart primary 13M 1000M

# assemble the partitions
	dd if=$(out)/efi.img of=$(out)/klos.img bs=1M seek=2 conv=notrunc
	dd if=$(out)/kfs.img of=$(out)/klos.img bs=1M seek=12 conv=notrunc

# sudo dd if=out/klos.img of=/dev/sda

### UTILS
#
#

$(out):
	mkdir -p $(out)

qemu:
	qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -D ./qemulog.txt -hda $(out)/klos.img -d int -no-reboot -M memory-backend=foo.ram -object memory-backend-file,size=1G,id=foo.ram,mem-path=ram.bin,share=on,prealloc=on -accel kvm
qemudebug:
	qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -s -S -D ./qemulog.txt -hda $(out)/klos.img -d int -no-reboot -monitor stdio -M memory-backend=foo.ram -object memory-backend-file,size=1G,id=foo.ram,mem-path=ram.bin,share=on,prealloc=on

clean:
	rm -rf $(out)