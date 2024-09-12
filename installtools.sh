# installs everything required using apt
apt -y update
apt -y install nasm qemu-system-x86 make wget python3 parted
bash ./bintil_cross.sh
bash ./gcc_cross.sh
bash ./limine_inst.sh