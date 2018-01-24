#!/bin/sh -e
DIR=$PWD
mkdir -p ${DIR}/deploy/
unset CC
CC=/home/zhe/am335x/gcc-linaro-arm-linux-gnueabihf-4.9/bin/arm-linux-gnueabihf-
export CC
echo "CROSS_COMPILE=${CC}"

make_menuconfig () {
	cd ${DIR}/KERNEL/
	cp -v ${DIR}/patches/defconfig .config
	make ARCH=arm CROSS_COMPILE="${CC}" menuconfig
	cp -v .config ${DIR}/patches/defconfig
	cd ${DIR}/
}

config="omap2plus_defconfig"

#toolchain="gcc_linaro_eabi_4_8"
#toolchain="gcc_linaro_eabi_4_9"
#toolchain="gcc_linaro_gnueabi_4_6"
toolchain="gcc_linaro_gnueabihf_4_7"
#toolchain="gcc_linaro_gnueabihf_4_8"
#toolchain="gcc_linaro_gnueabihf_4_9"

#Kernel/Build
KERNEL_REL=3.8
KERNEL_TAG=${KERNEL_REL}.13
BUILD=bone70

DISTRO=cross
DEBARCH=armhf

make_menuconfig

