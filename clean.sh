#!/bin/sh -e
DIR=$PWD
mkdir -p ${DIR}/deploy/
unset CC
CC=/home/zhe/am335x/gcc-linaro-arm-linux-gnueabihf-4.9/bin/arm-linux-gnueabihf-
export CC
echo "CROSS_COMPILE=${CC}"
cd ${DIR}/KERNEL/
make ARCH=arm CROSS_COMPILE="${CC}" clean
cd ${DIR}
