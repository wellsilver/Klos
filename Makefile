# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
cc = /usr/local/x86_64elfgcc/bin/x86_64-elf-gcc
src = src
out = out
imagesize = 50M

build: $(out) $(out)/lowkernel.bin $(out)/entry.bin $(out)/bootloader.bin $(out)/klos.img
run: $(out) $(out)/lowkernel.bin $(out)/entry.bin $(out)/bootloader.bin $(out)/klos.img qemu clean

$(out):
	mkdir $(out)

# compile things
$(out)/lowkernel.bin:
	$(cc) -c $(src)/lowkernel/main.c -masm=intel -g -Os -o $(out)/lowkernel.bin
	objcopy --only-keep-debug $(out)/lowkernel.bin $(out)/lowkernel.sym
	objcopy --strip-debug $(out)/lowkernel.bin

$(out)/entry.bin:
	$(asmc) $(src)/entry.asm -f bin -o $(out)/entry.bin
#	objcopy --only-keep-debug $(out)/entry.bin $(out)/entry.sym
#	objcopy --strip-debug $(out)/entry.bin

$(out)/bootloader.bin:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/bootloader.bin

# IF YOU CHANGED $(out) image.py IS WHERE THE ERROR IS
$(out)/klos.img:
	python3 image.py

qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 $(out)/klos.img

clean:
	rm -r $(out)