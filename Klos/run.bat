cargo build -Z build-std --target target.json --release
qemu-system-x86_64 -drive format=raw,file=target/target/release/bootimage-Klos.bin