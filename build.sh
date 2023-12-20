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
nasm flex bison libstdc++-dev meson \
imagemagick # Because there is no png icon yet; FIXME

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
./default-configure --prefix=/usr
make -j $(nproc)
make install DESTDIR=$(readlink -f appdir) install ; find appdir/
mkdir -p appdir/usr/share/icons/hicolor/256x256/apps/
convert -resize 256x256 appdir/usr/share/dosemu/icons/dosemu.xpm appdir/usr/share/icons/hicolor/256x256/apps/dosemu.png

# Fix desktop fie
cat > appdir/usr/share/applications/dosemu.desktop <<\EOF
[Desktop Entry]
Name=dosemu2
Comment=DOS emulator
Exec=dosemu
Icon=dosemu.png
Categories=System;Emulator;
EOF

# Create AppImage
ARCHITECTURE="x86_64" # TODO: Set based on the build system
wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimagetool-.*-${ARCHITECTURE}.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage
./appimagetool-*.AppImage -s deploy ./appdir/usr/share/applications/*.desktop --appimage-extract-and-run
VERSION=1.0 ./appimagetool-*.AppImage ./appdir --appimage-extract-and-run # Turn AppDir into AppImage
