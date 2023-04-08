# to clean, delete the out folder

asmc = nasm
cc = gcc
src = src
out = out
imagesize = 50M

build: $(out) $(out)/kernel.bin $(out)/bootloader.bin $(out)/klos.img
run: $(out) $(out)/kernel.bin $(out)/bootloader.bin $(out)/klos.img qemu clean

$(out):
	mkdir $(out)

# compile things
$(out)/kernel.bin:
	$(cc) -c $(src)/kernel.c -masm=intel -o $(out)/kernelunstripped.o
	objcopy -O binary -j .text $(out)/kernelunstripped.o $(out)/kernel.bin

$(out)/bootloader.bin:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/bootloader.bin

$(out)/klos.img:
	cat $(out)/bootloader.bin $(out)/kernel.bin > $(out)/klos.img
	truncate $(out)/klos.img -s 5M

qemu:
	qemu-system-x86_64 -fda $(out)/klos.img

clean:
	rm -r $(out)