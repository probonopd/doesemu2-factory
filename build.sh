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

# Build and install Linuxbrew which is needed to build newer versions of fdpp
apk add curl file gzip libc6-compat ncurses ruby ruby-dbm ruby-etc ruby-irb ruby-json sudo
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
PATH=$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH
brew update
brew doctor

# Build FDPP which is a dependency of dosemu2
git clone https://github.com/dosemu2/fdpp
cd fdpp
# wget https://github.com/dosemu2/fdpp/archive/refs/tags/1.4.tar.gz
# tar -zxf 1.4.tar.gz
# cd fdpp-1.4
make -j $(nproc)
make install
cd -
 
# Build dosemu2
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
# autoreconf --install -v -I m4
make -j $(nproc)
