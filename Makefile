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
	x86_64-elf-gcc -c $(src)/kernel/main.c -o $(out)/kernel.bin -masm=intel -g -Os
	objcopy --only-keep-debug $(out)/kernel.bin $(out)/kernel.sym
	objcopy --strip-debug $(out)/kernel.bin

# IF YOU CHANGED $(out) kfs.py IS WHERE THE ERROR IS
$(out)/klos.img:
	python3 kfs.py -s $(imagesize) -boot $(out)/boot.bin -f "kernel" $(out)/kernel.bin -o $(out)/klos.img
	
qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 -drive file=$(out)/klos.img -m 4G
clean:
	rm -r $(out)