elfbin="$1"
cd $elfbin
wget http://mirror.koddos.net/gcc/releases/gcc-13.2.0/gcc-13.2.0.tar.gz
tar -xf gcc-13.2.0.tar.gz
# below breaks alot, should reinstall it
sudo apt -y remove build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
sudo apt -y install build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
# just realized all distributions dont have apt 🤦‍♂️
mkdir build
cd build
../gcc-13.2.0/configure --target=x86_64-elf --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc -j 4
make all-target-libgcc -j 4
make install-gcc -j 4
make install-target-libgcc -j 4