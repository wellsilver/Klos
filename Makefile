# to clean, delete the out folder

asmc = nasm
# must be x86_64 no_os elf
elfbin = /usr/local/x86_64elfgcc/bin
src = src
out = out
imagesize = 50M

build: $(out) $(out)/boot.bin $(out)/kernel.efi $(out)/klos.img 
run: $(out) $(out)/boot.bin $(out)/kernel.efi $(out)/klos.img qemu clean

$(out):
	mkdir $(out)

# compile things
$(out)/boot.bin:
	nasm $(src)/boot.asm --target=x86_64-none $(out)/boot.bin

$(out)/kernel.bin:
	

# IF YOU CHANGED $(out) kfs.py IS WHERE THE ERROR IS
$(out)/klos.img:
	python kfs.py
	dd if=$(out)/boot.bin of=$(out)/klos.img
	truncate $(out)/klos.img -s 5M

qemu:
	echo If wsl does not spawn a gui, switch to a popular distribution on wsl2 and restart until it works, otherwise instructions in https://github.com/microsoft/WSL/issues/4106
	qemu-system-x86_64 -drive file=$(out)/klos.img -m 4G
clean:
	rm -r $(out)