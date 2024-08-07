# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil
# 50 megabytes
imagesize = 97656

build: $(out) $(out)/biosboot.bin $(out)/kernel.bin $(out)/klos.img 
run: $(out) $(out)/biosboot.bin $(out)/kernel.bin $(out)/klos.img qemu clean
debug: build qemudebug clean

$(out):
	mkdir -p $(out)

$(out)/biosboot.bin:
	nasm $(src)/boot.asm -f bin -o $(out)/biosboot.bin
	truncate $(out)/biosboot.bin -s 1536

$(out)/kernel.bin:
	nasm $(src)/kernel/main.asm -f elf64 -o $(out)/main.asm.bin
	x86_64-elf-gcc -nostdlib -I $(src)/kernel -T $(src)/kernel/linker.ld $(out)/main.asm.bin $(src)/kernel/main.c -masm=intel -g -O0 -o $(out)/kernel.elf
	objcopy -O binary $(out)/kernel.elf $(out)/kernel.bin
	x86_64-elf-objdump -M intel -d out/kernel.elf > out/kernel.asm

$(out)/klos.img:
	python3 kfs/format.py $(out)/klos.img $(imagesize) $(out)/biosboot.bin $(out)/kernel.bin
	
qemu:
	qemu-system-x86_64 -D ./qemulog.txt -drive file=$(out)/klos.img -m 4G -d int -no-reboot
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -drive file=$(out)/klos.img -m 4G -d int -no-reboot

clean:
	rm -rf $(out)