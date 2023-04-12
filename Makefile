# to clean, delete the out folder

asmc = nasm
cc = /usr/local/x86_64elfgcc/bin/x86_64-elf-gcc
src = src
out = out
imagesize = 50M

build: $(out) $(out)/bootloader.bin $(out)/entry.bin $(out)/kernel.bin $(out)/klos.img
run: $(out) $(out)/bootloader.bin $(out)/entry.bin $(out)/kernel.bin $(out)/klos.img qemu clean

$(out):
	mkdir $(out)

# compile things
$(out)/entry.bin:
	$(cc) -c $(src)/entry.c -masm=intel -g -o $(out)/entry.bin
	objcopy --only-keep-debug $(out)/entry.bin $(out)/entry.sym
	objcopy --strip-debug $(out)/entry.bin
	truncate $(out)/entry.bin -s 512

$(out)/kernel.bin:
	$(cc) -c $(src)/kernel/main.c -masm=intel -g -o $(out)/kernel.bin
	objcopy --only-keep-debug $(out)/kernel.bin $(out)/kernel.sym
	objcopy --strip-debug $(out)/kernel.bin

$(out)/bootloader.bin:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/bootloader.bin

$(out)/klos.img:
	dd if=/dev/zero of=$(out)/klos.img bs=512 count=2880
	mkfs.fat -F 32 -n "NBOS" $(out)/klos.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(out)/klos.img conv=notrunc
	mcopy -i $(out)/klos.img $(BUILD_DIR)/entry.bin "::kernel.bin"
	mcopy -i $(out)/klos.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 $(out)/klos.img

clean:
	rm -r $(out)