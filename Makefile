asmc = nasm
cc = gcc
src = src
out = out

main:
	$(asmc) $(src)/boot.asm -f bin -o $(out)/os.img

run:
	qemu-system-i386 -fda $(out)/os.img