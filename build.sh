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
nasm flex bison libstdc++-dev

# git clone https://github.com/dosemu2/fdpp
# cd fdpp
wget https://github.com/dosemu2/fdpp/archive/refs/tags/1.4.tar.gz
tar -zxf /tmp/1.4.tar.gz
cd fdpp-1.4
make -j $(nproc)
make install
cd -
 
# Build
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
# autoreconf --install -v -I m4
make -j $(nproc)
