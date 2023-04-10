# to clean, delete the out folder

asmc = nasm
cc = /usr/local/x86_64elfgcc/bin/x86_64-elf-gcc
src = src
out = out
imagesize = 50M

build: $(out) $(out)/kernel.bin $(out)/bootloader.bin $(out)/klos.img
run: $(out) $(out)/kernel.bin $(out)/bootloader.bin $(out)/klos.img qemu clean

$(out):
	mkdir $(out)

# compile things
$(out)/kernel.bin:
	$(cc) -c $(src)/kernel.c -masm=intel -g -o $(out)/kernel.bin
	objcopy --only-keep-debug $(out)/kernel.bin $(out)/kernel.sym
	objcopy --strip-debug $(out)/kernel.bin

$(out)/bootloader.bin:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/bootloader.bin

$(out)/klos.img:
	cat $(out)/bootloader.bin $(out)/kernel.bin > $(out)/klos.img
	truncate $(out)/klos.img -s 50M

qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 $(out)/klos.img

clean:
	rm -r $(out)