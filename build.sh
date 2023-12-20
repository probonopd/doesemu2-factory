#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

# Install build dependencies
apk update
apk add ca-certificates build-base wget git bash clang nasm elfutils-dev flex bison \
autoconf git coreutils automake gawk pkgconfig linux-headers libbsd-dev \
nasm flex bison libstdc++-dev meson

# Build and install nasm-segelf which is a dependency of FDPP (newer versions)
# Is this documented somewhere?
ln -s $(which ld) /usr/local/bin/x86_64-linux-gnu-ld
git clone https://github.com/stsp/nasm
cd nasm
./configure
make -j $(nproc)
make install
cd -

# Build FDPP which is a dependency of dosemu2
git clone https://github.com/dosemu2/fdpp
cd fdpp
# wget https://github.com/dosemu2/fdpp/archive/refs/tags/1.4.tar.gz
# tar -zxf 1.4.tar.gz
# cd fdpp-1.4
cd fdpp
make -j $(nproc)
make install
cd -
 
# Build dosemu2
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
# wget https://github.com/dosemu2/dosemu2/archive/refs/tags/2.0pre9.tar.gz
# tar -zxf 2.0pre9.tar.gz
cd dosemu2-2.0pre9
# autoreconf --install -v -I m4
make -j $(nproc)
ls -lh
