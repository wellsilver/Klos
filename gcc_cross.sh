mkdir /tmp/gccbuild
cd /tmp/gccbuild
wget http://mirror.koddos.net/gcc/releases/gcc-13.2.0/gcc-13.2.0.tar.gz
tar -xf gcc-13.2.0.tar.gz
# below breaks alot, should reinstall it
apt -y remove build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
apt -y install build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
# just realized all distributions dont have apt 🤦‍♂️
mkdir build
cd build
../gcc-13.2.0/configure --target=x86_64-elf --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc -j 12
make all-target-libgcc -j 12
make install-gcc -j 12
make install-target-libgcc -j 12