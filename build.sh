#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

# Install build dependencies
apk update
apk add ca-certificates build-base wget git bash clang elfutils-dev flex bison \
autoconf git coreutils automake gawk pkgconfig linux-headers libbsd-dev \
flex bison libstdc++-dev findutils meson sdl2-dev sdl2 alsa-lib-dev alsa-plugins alsa-plugins-pulse \
sdl2_ttf-dev fontconfig fontconfig-dev libxscrnsaver libxrandr libxkbcommon libxi libxfixes libxext \
libxcursor libx11 wayland-libs-egl wayland-libs-cursor wayland-libs-client eudev libsamplerate \
mesa-gl mesa-gles mesa-gbm mesa-egl libdrm alsa-lib \
imagemagick # Because there is no png icon yet; FIXME

# Build and install nasm-segelf which is a dependency of FDPP (newer versions)
# Is this documented somewhere?
git clone https://github.com/stsp/nasm
cd nasm
./configure
make -j $(nproc)
make install
cd -

# Build FDPP which is a dependency of dosemu2
git clone https://github.com/dosemu2/fdpp
cd fdpp
./configure.meson build --prefix=/usr
meson compile --verbose -C build
meson install -C build
cd -
 
# Build dosemu2
git clone https://github.com/dosemu2/dosemu2
cd dosemu2
# git checkout 58bf3c1 # Known working commit
export VERSION=$(git rev-parse --short HEAD)
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

# find /usr | grep libfdpp
# ldd appdir/usr/bin/dosemu.bin

# Get install-freedos scripts
git clone https://github.com/dosemu2/install-freedos
cd install-freedos
make prefix=$(readlink -f ../appdir) install
cd ..

# Workaround because appimagetool can't deal with non-ELF main executables
mv appdir/usr/bin/dosemu appdir/usr/bin/dosemu.script
mv appdir/usr/bin/dosemu.bin appdir/usr/bin/dosemu

# Declare the undeclared dependencies of libSDL2
ARCHITECTURE="x86_64" # TODO: Set based on the build system
wget -c -q https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimagetool-.*-${ARCHITECTURE}.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage
./appimagetool-*.AppImage --appimage-extract
cp /usr/lib/libSDL2-2.0.so.0 /usr/lib/libSDL2-2.0.so.0.original
./squashfs-root/usr/bin/patchelf --add-needed libasound.so.2 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libdirectfb-1.7.so.7 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libdrm.so.2 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libEGL.so.1 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libgbm.so.1 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libGLES_CM.so.1 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libGLESv1_CM.so.1 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libGLESv2.so.2 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libGL.so.1 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libjack.so.0 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libOpenGL.so.0 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libpipewire-0.3.so.0 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libpulse-simple.so.0 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libsamplerate.so.0 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libudev.so.0 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libudev.so.1 /usr/lib/libSDL2-2.0.so.0
# ./squashfs-root/usr/bin/patchelf --add-needed libvulkan.so.1 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libwayland-client.so.0 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libwayland-cursor.so.0 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libwayland-egl.so.1 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libX11.so.6 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libX11-xcb.so /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libXcursor.so.1 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libXext.so.6 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libXfixes.so.3 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libXi.so.6 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libxkbcommon.so.0 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libXrandr.so.2 /usr/lib/libSDL2-2.0.so.0
./squashfs-root/usr/bin/patchelf --add-needed libXss.so.1 /usr/lib/libSDL2-2.0.so.0

# Deploy dependencies into AppDir
./appimagetool-*.AppImage -s deploy ./appdir/usr/share/applications/*.desktop --appimage-extract-and-run

# Get precompiled command.com and put it into the AppDir
mkdir -p ./appdir/usr/share/comcom32/
wget -c -q https://dosemu2.github.io/comcom32/files/comcom32.zip
unzip -o comcom32.zip -d ./appdir/usr/share/comcom32/
mv appdir/usr/share/comcom32/comcom32.exe appdir/usr/share/comcom32/command.com

# FreeDOS - optional and not needed for the intended purpose. Also slow and pulls in depenedncies (py3-pip, tqdm from pip)
# pip3 install tqdm
# ./appdir/libexec/dosemu/dosemu-installfreedosuserspace
# TODO: Pick it up from wherever it got installed to, and copy it into the AppDir

# Workaround for paths to PREFIX that get compiled in at build time
sed -i -e 's|/usr|././|g' appdir/usr/bin/dosemu
sed -i -e 's|/usr|././|g' appdir/usr/lib/fdpp/libfdldr.so.*

# ALSA patching... don't ask ;-)
find appdir/usr/lib -type f -exec sed -i -e 's|/usr|././|g' {} \;
mkdir -p appdir/usr/share/
( cd appdir/usr/share/ ; ln -s /usr/share/alsa . )
( cd appdir/usr/lib/alsa-lib ; ln -s ../ lib )

# dri
mkdir -p appdir/usr/lib/xorg/modules/
cp -r /usr/lib/xorg/modules/dri appdir/usr/lib/xorg/modules/

# Workaround for /usr/local/share/fdpp/
# FIXME: Once we get fdpp compiled to PREFIX /usr it will cleaner
# Doing this after "-s deploy", assuming we should not patch those files
mkdir -p appdir/usr/local/share/
rm -rf appdir/usr/share/fdpp 2>/dev/null || true
cp -r /usr/share/fdpp appdir/usr/share/

# Make relocation logic work even though main binary is executed via calling ld-linux
mv appdir/lib/ld-musl-*.so.1 appdir/usr/bin/

# TODO: Customize AppRun script to launch dosemu2 in a meaningful way (e.g., set reqiured variables, etc.)

# Convert AppDir to AppImage
./appimagetool-*.AppImage ./appdir --appimage-extract-and-run # Turn AppDir into AppImage
