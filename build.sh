#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

# Install build dependencies
apk update
apk add alsa-lib-dev \
    autoconf \
    bash \
    bdftopcf \
    bison \
    build-base \
    git \
    flex \
    fontconfig \
    libao-dev \
    linux-headers \
    mkfontdir \
    sdl2-dev \
    slang-dev \
    strace \
    file \
    libexecinfo-dev \
    gpm-dev

# Build
git clone https://github.com/dosemu2/dosemu2
cd /tmp/dosemu2
make -j $(nproc)
