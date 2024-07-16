# installs everything required using apt
apt -y update
apt -u install nasm qemu-system-x86 make wget
bash ./bintil_cross.sh
bash ./gcc_cross.sh
bash ./limine_inst.sh