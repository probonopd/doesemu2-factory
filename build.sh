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
make -j $(nproc)
make install
cd -
 
# Build dosemu2
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
# ./configure --prefix=/usr # FIXME: Does not exist; how to do this?
make -j $(nproc)
( mkdir -p appdir/usr ; cd appdir/usr ; ln -s . ./local ) # Bad hack, FIXME: Remove
make install DESTDIR=$(readlink -f appdir) install ; find appdir/

# Create AppImage
wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimagetool-.*-${ARCHITECTURE}.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage
./appimagetool-*.AppImage -s deploy ./appdir/usr/share/applications/*.desktop --appimage-extract-and-run
VERSION=1.0 ./appimagetool-*.AppImage ./appdir --appimage-extract-and-run # Turn AppDir into AppImage
