#!/usr/bin/env sh

set -e

git clone --depth=1 https://github.com/raspberrypi/linux

cd linux

KERNEL=kernel8; make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs
