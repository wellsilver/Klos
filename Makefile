# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
src = src
out = out
elfbin = $(out)/gcc
bintilbin = $(out)/binutil
imagesize = 50M

build: $(out) $(out)/binutil $(out)/gcc $(out)/boot.bin $(out)/kernel.bin $(out)/klos.img 
run: $(out) $(out)/binutil $(out)/gcc $(out)/boot.bin $(out)/kernel.bin $(out)/klos.img qemu clean

$(out):
	mkdir $(out)

$(out)/binutil:
	mkdir $(bintilbin)
	bash bintil_cross.sh $(bintilbin)

$(out)/gcc:
	mkdir $(elfbin)
	bash gcc_cross.sh $(elfbin)

# compile things
$(out)/boot.bin:
	nasm $(src)/boot.asm -f bin -o $(out)/boot.bin
	truncate $(out)/boot.bin -s 1536

$(out)/kernel.bin:
	

# IF YOU CHANGED $(out) kfs.py IS WHERE THE ERROR IS
$(out)/klos.img:
	python kfs.py
	dd if=$(out)/boot.bin of=$(out)/klos.img
	truncate $(out)/klos.img -s $(imagesize)

qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 -drive file=$(out)/klos.img -m 4G
clean:
	rm -r $(out)