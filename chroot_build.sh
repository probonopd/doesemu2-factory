#!/bin/sh

set -ex

#############################################
# Download and extract minimal Alpine system
#############################################

wget "http://dl-cdn.alpinelinux.org/alpine/v3.19/releases/${ARCHITECTURE}/alpine-minirootfs-3.19.0-${ARCHITECTURE}.tar.gz"
sudo rm -rf ./miniroot  true # Clean up from previous runs
mkdir -p ./miniroot
cd ./miniroot
sudo tar xf ../alpine-minirootfs-*-"${ARCHITECTURE}".tar.gz
cd -

#############################################
# Prepare chroot
#############################################

sudo mount -o bind /dev miniroot/dev
sudo mount -t proc none miniroot/proc
sudo mount -t sysfs none miniroot/sys
sudo cp -p /etc/resolv.conf miniroot/etc/

#############################################
# Run build.sh in chroot
#############################################

if [ "$ARCHITECTURE" = "x86" ] || [ "$ARCHITECTURE" = "x86_64" ]; then
    echo "Architecture is x86 or x86_64, hence not using qemu-arm-static"
    sudo cp build.sh miniroot/build.sh && sudo chroot miniroot /bin/sh -ex /build.sh
elif [ "$ARCHITECTURE" = "aarch64" ] ; then
    echo "Architecture is aarch64, hence using qemu-aarch64-static"
    sudo cp "$(which qemu-aarch64-static)" miniroot/usr/bin
    sudo cp build.sh miniroot/build.sh && sudo chroot miniroot qemu-aarch64-static /bin/sh -ex /build.sh
elif [ "$ARCHITECTURE" = "armhf" ] ; then
    echo "Architecture is armhf, hence using qemu-arm-static"
    sudo cp "$(which qemu-arm-static)" miniroot/usr/bin
    sudo cp build.sh miniroot/build.sh && sudo chroot miniroot qemu-arm-static /bin/sh -ex /build.sh
else
    echo "Edit chroot_build.sh to support this architecture as well, it should be easy"
    exit 1
fi

#############################################
# Clean up chroot
#############################################

sudo umount miniroot/proc miniroot/sys miniroot/dev

#############################################
# Copy build artefacts out
#############################################

# Use the same architecture names as https://github.com/AppImage/AppImageKit/releases/
if [ "$ARCHITECTURE" = "x86" ] ; then ARCHITECTURE=i686 ; fi

mkdir out/
cp miniroot/dosemu2/dosemu2-*.AppImage out/
sudo rm -rf miniroot/
