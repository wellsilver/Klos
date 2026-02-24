
src  = src
out  = out
asmc = nasm
CC   = x86_64-elf-gcc

### KERNEL COMPILATION
#
#

kernelcsources := $(shell find $(src)/kernel -name "*.c")
kernelobjects := $(patsubst %.c, out/%.o, $(notdir $(kernelcsources)))
kerneltarget := x86_64

kernelargs = -I $(src)/kernel -I $(src)/kernel/util -nostdinc -nostdlib -Os -g -c -masm=intel -mcmodel=large -ffreestanding -mgeneral-regs-only -mno-red-zone

$(out)/main.$(kerneltarget).elf: $(src)/kernel/arch/main.$(kerneltarget).S | $(out)
	nasm $< -f elf64 -o $(out)/main.$(kerneltarget).elf

$(out)/kernel.elf: $(kernelobjects) $(out)/main.$(kerneltarget).elf | $(out) $(src)/kernel/linker.ld
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

# Legacy BIOS
$(out)/biosboot.bin: $(src)/biosboot.S | $(out)
	nasm $(src)/biosboot.S -o $(out)/biosboot.bin

### DISK IMAGE
#
#

# Filesystem, no partition table, BIOS BOOT (out/kfs.img)
$(out)/kfs.img: $(out)/biosboot.bin $(out)/kernel.elf | $(out)
	python3 kfs/format.py $(out)/kfs.img 1000 $(out)/biosboot.bin $(out)/kernel.elf

# Generic GPT UEFI BOOT (out/klos.img)
$(out)/klos_uefi.img: $(out)/kfs.img $(out)/BOOTX64.efi $(out)/kernel.elf $(out)/biosboot.bin | $(out)
# format the efi fs
#	mkfs.fat -C -F 32 $(out)/efi.img 20480
	truncate $(out)/efi.img -s 12M
	mformat -i $(out)/efi.img
	mmd -i $(out)/efi.img ::/EFI ::/EFI/BOOT ::/boot

# Copy UEFI bootloader efi.img
	mcopy -i $(out)/efi.img $(out)/BOOTX64.EFI ::/EFI/BOOT

# create the disc image with a efi and kfs partition - 100M not a special number
	truncate $(out)/klos_uefi.img -s 100M
	parted $(out)/klos_uefi.img --script mklabel gpt
	parted $(out)/klos_uefi.img mkpart EFI FAT32 2048s 2MiB
	parted $(out)/klos_uefi.img mkpart klos 2MiB 100%

# copy partitions to the disc image
	dd if=$(out)/efi.img of=$(out)/klos_uefi.img bs=512 seek=2048
	dd if=$(out)/kfs.img of=$(out)/klos_uefi.img seek=2MiB

# sudo dd if=out/klos.img of=/dev/sda

# CDROM (El Torito) BIOS BOOT (out/klos_eltorito.iso)
$(out)/klos_eltorito.iso: $(out)/kfs.img
	xorriso -as mkisofs -b kfs.img -no-emul-boot -boot-load-size 4 -o $(out)/klos_eltorito.iso $(out)/kfs.img

### UTILS
#
#

$(out):
	mkdir -p $(out)

qemu: $(out)/klos_uefi.img
	qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -D ./qemulog.txt -hda $(out)/klos_uefi.img -d int,mmu -no-reboot -m 1G
qemu-bios: $(out)/klos_eltorito.iso
	qemu-system-x86_64 -cdrom $(out)/klos_eltorito.iso -D ./qemulog.txt -d int,mmu -no-reboot -m 1G -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios
qemudebug: $(out)/klos_uefi.img
	qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -s -S -D ./qemulog.txt -hda $(out)/klos_uefi.img -d int,mmu -no-reboot -monitor stdio -M memory-backend=foo.ram -object memory-backend-file,size=1G,id=foo.ram,mem-path=ram.bin,share=on,prealloc=on -m 1G
bochs: $(out)/klos_eltorito.iso
	bochs -dbg_gui -q 'boot:cdrom' 'ata0-master: type=cdrom, path=out/klos_eltorito.iso, status=inserted'

build: $(out)/klos.img
all: qemu

clean:
	rm -rf $(out)