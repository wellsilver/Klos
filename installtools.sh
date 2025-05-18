# installs everything required using apt
apt -y update
apt -y install nasm qemu-system-x86 make wget python3 parted lld clang
bash ./bintil_cross.sh
bash ./gcc_cross.sh