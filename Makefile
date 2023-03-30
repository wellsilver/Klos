asmc = nasm
cc = gcc
src = src
out = out

all: main run

main:
	mkdir out
	$(asmc) $(src)/boot.asm -f bin -o $(out)/os.img

run:
	qemu-system-x86_64 -fda $(out)/os.img