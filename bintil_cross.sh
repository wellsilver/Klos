mkdir /tmp/bintilbuild
cd /tmp/bintilbuild
wget https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.gz
tar -xf binutils-2.41.tar.gz
# below breaks alot, should reinstall it
apt -y remove build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
apt -y install build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
# just realized all distributions dont have apt 🤦‍♂️
mkdir build
cd build
../binutils-2.41/configure --target=x86_64-elf --with-sysroot --disable-nls --disable-werror
make -j 6
make install -j 6