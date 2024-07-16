mkdir /tmp/liminebuild
cd /tmp/liminebuild
# update git link with latest limine version
git clone https://github.com/limine-bootloader/limine.git --branch=v7.x-binary .
make
make install