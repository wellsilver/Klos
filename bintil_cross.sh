elfbin="$1"
cd $elfbin
wget https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.gz
tar -xf binutils-2.41.tar.gz
# below breaks alot, should reinstall it
sudo apt -y remove build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
sudo apt -y install build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
mkdir build
cd build
../binutils-2.41/configure --target=amd64-none-elf --with-sysroot --disable-nls --disable-werror
make -j 4
make install -j 4