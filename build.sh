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
nasm flex bison libstdc++-dev meson findutils pipx \
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
pipx install meson
git clone https://github.com/dosemu2/fdpp
cd fdpp
./configure.meson build
meson compile --verbose -C build
sudo meson install -C build
cd -
 
# Build dosemu2
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
git checkout fedae32 # TODO: Remove this
./default-configure --prefix=/usr
make -j $(nproc)
make install DESTDIR=$(readlink -f appdir) install ; find appdir/
mkdir -p appdir/usr/share/icons/hicolor/256x256/apps/
convert -resize 256x256 appdir/usr/share/dosemu/icons/dosemu.xpm appdir/usr/share/icons/hicolor/256x256/apps/dosemu.png

# Fix desktop fie
cat > appdir/usr/share/applications/dosemu.desktop <<\EOF
[Desktop Entry]
Name=dosemu2
Type=Application
Comment=DOS emulator
Exec=dosemu
Icon=dosemu
Categories=System;Emulator;
EOF

find /usr | grep libfdpp
ldd appdir/usr/bin/dosemu.bin

# Get install-freedos scripts
git clone https://github.com/dosemu2/install-freedos
cd install-freedos
make prefix=$(readlink -f ../appdir) install
cd ..

# Workaround for non-standard library location
cp /usr/local/lib/fdpp/* /usr/lib/
export LD_LIBRARY_PATH=/usr/local/lib/fdpp/

# Workaround because appimagetool can't deal with non-ELF main executables
mv appdir/usr/bin/dosemu appdir/usr/bin/dosemu.script
mv appdir/usr/bin/dosemu.bin appdir/usr/bin/dosemu

# Deploy dependencies into AppDir
ARCHITECTURE="x86_64" # TODO: Set based on the build system
wget -c -q https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimagetool-.*-${ARCHITECTURE}.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage
./appimagetool-*.AppImage -s deploy ./appdir/usr/share/applications/*.desktop --appimage-extract-and-run

# Workaround for paths to PREFIX that get compiled in at build time
sed -i -e 's|/usr|././|g' appdir/usr/bin/dosemu
sed -i -e 's|/usr|././|g' appdir/usr/lib/libfdldr.so.*

# Workaround for /usr/local/share/fdpp/
# FIXME: Once we get fdpp compiled to PREFIX /usr it will cleaner
# Doing theis after "-s deploy", assuming we should not patch those files
mkdir -p appdir/usr/local/share/
cp -r /usr/local/share/fdpp appdir/usr/local/share/

# TODO: Customize AppRun script to launch dosemu2 in a meaningful way (e.g., set reqiured variables, etc.)

# Convert AppDir to AppImage
VERSION=1.0 ./appimagetool-*.AppImage ./appdir --appimage-extract-and-run # Turn AppDir into AppImage
