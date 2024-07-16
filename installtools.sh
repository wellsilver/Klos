# installs everything required using apt
sudo apt update
sudo apt install nasm qemu-system-x86 make truncate wget
sudo bash ./bintil_cross.sh
sudo bash ./gcc_cross.sh
sudo bash ./limine_inst.sh