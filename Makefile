# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
elfbin = /usr/local/x86_64elfgcc/bin
src = src
out = out
imagesize = 50M

build: $(out) $(out)/kernel.bin $(out)/BOOTX64.efi $(out)/klos.img 
run: $(out) $(out)/kernel.bin $(out)/BOOTX64.efi $(out)/klos.img  qemu clean

$(out):
	mkdir $(out)

# compile things
$(out)/kernel.bin:
	$(elfbin)/x86_64-elf-gcc -c $(src)/kernel/main.c -masm=intel -g -Os -o $(out)/kernel.bin
	objcopy --only-keep-debug $(out)/kernel.bin $(out)/kernel.sym
	objcopy --strip-debug $(out)/kernel.bin

$(out)/BOOTX64.efi:
	$(elfbin)/x86_64-elf-gcc $(src)/uefi.c -c -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -I /usr/include -I /usr/include/efi/x86_64 -I /usr/include/x86_64-linux-gnu -DEFI_FUNCTION_WRAPPER -ffreestanding -o $(out)/main.o
	$(elfbin)/x86_64-elf-ld $(out)/main.o /usr/lib/crt0-efi-x86_64.o -nostdlib -znocombreloc -T /usr/lib/elf_x86_64_efi.lds -shared -Bsymbolic -L /usr/lib -lgnuefi -lefi -o $(out)/main.so
	objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64 $(out)/main.so $(out)/BOOTX64.efi

# IF YOU CHANGED $(out) image.py IS WHERE THE ERROR IS
$(out)/klos.img:
	dd if=/dev/zero of=$(out)/klos.img bs=512 count=93750
	parted $(out)/klos.img -s -a minimal mklabel gpt
	parted $(out)/klos.img -s -a minimal mkpart EFI FAT16 2048s 93716s
	parted $(out)/klos.img -s -a minimal toggle 1 boot
	dd if=/dev/zero of=$(out)/part.img bs=512 count=91669
	mformat -i $(out)/part.img -h 32 -t 32 -n 64 -c 1
	mmd -i $(out)/part.img ::/EFI
	mmd -i $(out)/part.img ::/EFI/BOOT
	mcopy -i $(out)/part.img $(out)/BOOTX64.efi ::/EFI/BOOT/
#	mcopy -i $(out)/part.img Resources/zap-light16.psf :: 
	dd if=$(out)/part.img of=$(out)/klos.img bs=512 count=91669 seek=2048 conv=notrunc
#	mcopy -i $(out)/klos.img $(BUILDDIR)/kernel.elf ::

qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -drive file=$(out)/klos.img -m 4G

clean:
	rm -r $(out)