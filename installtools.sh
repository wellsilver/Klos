# installs everything required using apt
apt update
apt install nasm qemu-system-x86 make truncate wget
bash ./bintil_cross.sh
bash ./gcc_cross.sh
bash ./limine_inst.sh