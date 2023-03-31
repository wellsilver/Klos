# to clean, delete the out folder

asmc = nasm
cc = gcc
src = src
out = out

all: $(out) $(out)/kernel.bin $(out)/bootloader.bin $(out)/klos.img run

$(out):
	mkdir $(out)

# compile things
$(out)/kernel.bin:
	$(cc) -c $(src)/kernel.c -o $(out)/kernelunstripped.o
	objcopy -O binary -j .text $(out)/kernelunstripped.o $(out)/kernel.bin

$(out)/bootloader.bin:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/bootloader.bin

ifeq ($(OS), Windows_NT)
$(out)/klos.img:
	powershell "Get-Content -Raw $(out)/bootloader.bin, $(out)/kernel.bin | Set-Content -NoNewline $(out)/klos.img"
else
$(out)/klos.img:
	cat $(out)/bootloader.bin $(out)/kernel.bin > $(out)/klos.img
endif

run:
	qemu-system-x86_64 -fda $(out)/klos.img