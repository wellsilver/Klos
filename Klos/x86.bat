cargo bootimage -Z build-std --target x86.json --release
qemu-system-x86_64 -drive format=raw,file=target/x86/release/bootimage-Klos.bin
pause