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
	$(cc) -c $(src)/kernel.c -masm=intel -o $(out)/kernel.bin

$(out)/bootloader.bin:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/bootloader.bin

$(out)/klos.img:
	cat $(out)/bootloader.bin $(out)/kernel.bin > $(out)/klos.img
	truncate $(out)/klos.img -s 5M

qemu:
	echo If your using wsl and qemu does not work, switch to a popular distribution on wsl2 and restart it until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 -fda $(out)/klos.img

clean:
	rm -r $(out)