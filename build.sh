#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

# Install build dependencies
apk update
apk add ca-certificates build-base wget git bash clang nasm elfutils-dev flex bison autoconf git coreutils automake gawk pkgconfig linux-headers libbsd-dev

# Build
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
autoreconf --install -v -I m4
make -j $(nproc)
