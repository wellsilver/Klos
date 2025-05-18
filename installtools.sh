# installs everything required using apt
apt -y update
# sometimes parted is not put in /usr/bin even though its usable on (as file) disk images....
# if that occurs sudo ln -s /usr/sbin/parted /usr/bin/parted
apt -y install nasm qemu-system-x86 make wget python3 parted mtools lld clang
bash ./bintil_cross.sh
bash ./gcc_cross.sh