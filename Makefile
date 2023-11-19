# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil
imagesize = 50M

build: $(out) x86_64-none-elf-objcopy x86_64-none-elf-gcc $(out)/boot.bin $(out)/kernel.bin $(out)/klos.img 
run: $(out) x86_64-none-elf-objcopy x86_64-none-elf-gcc $(out)/boot.bin $(out)/kernel.bin $(out)/klos.img qemu clean
debug: build qemudebug clean

$(out):
	mkdir -p $(out)

x86_64-none-elf-objcopy:
	mkdir -p $(bintilbin)
	@if ! command -v x86_64-elf-objcopy > /dev/null; then \
		bash bintil_cross.sh $(bintilbin); \
	fi

x86_64-none-elf-gcc:
	mkdir -p $(elfbin)
	@if ! command -v x86_64-elf-gcc > /dev/null; then \
		bash gcc_cross.sh $(elfbin); \
	fi

$(out)/boot.bin:
	nasm $(src)/boot.asm -f bin -o $(out)/boot.bin
	truncate $(out)/boot.bin -s 1536

$(out)/kernel.bin:
	x86_64-elf-gcc -nostdlib -I $(src)/kernel -T $(src)/kernel/linker.ld $(src)/kernel/main.c -masm=intel -g -Os -o $(out)/kernel.bin
#	objcopy -O binary $(out)/kernel.bin

$(out)/klos.img:
# kfs.py may fuck up the build if you change it or its parameters, check boot.asm
	python3 kfs.py -s $(imagesize) -boot $(out)/boot.bin -f "kernel" $(out)/kernel.bin -o $(out)/klos.img
	
qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 -D ./qemulog.txt -d cpu_reset -drive file=$(out)/klos.img -m 4G
qemudebug:
	qemu-system-x86_64 -s -S -D ./qemulog.txt -d cpu_reset -drive file=$(out)/klos.img -m 4G

clean:
	rm -r $(out)