# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil
# 50 megabytes
imagesize = 97656

build: $(out) $(out)/boot.bin $(out)/kernel.bin $(out)/klos.img 
run: $(out) $(out)/boot.bin $(out)/kernel.bin $(out)/klos.img qemu clean
debug: build qemudebug clean

$(out):
	mkdir -p $(out)

$(out)/boot.bin:
	nasm $(src)/boot.asm -f bin -o $(out)/boot.bin
	truncate $(out)/boot.bin -s 1536

$(out)/kernel.bin:
	x86_64-elf-gcc -nostdlib -I $(src)/kernel -T $(src)/kernel/linker.ld $(src)/kernel/main.c -masm=intel -g -Os -o $(out)/kernel.bin
#	objcopy -O binary $(out)/kernel.bin

$(out)/klos.img:
	python3 kfs/format.py $(out)/klos.img $(imagesize) $(out)/boot.bin $(out)/kernel.bin
	
qemu:
	qemu-system-x86_64 -D ./qemulog.txt -d cpu_reset -drive file=$(out)/klos.img -m 4G
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -d cpu_reset -drive file=$(out)/klos.img -m 4G

clean:
	rm -rf $(out)