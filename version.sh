#!/bin/sh
#
ARCH=$(uname -m)
CORES=$(getconf _NPROCESSORS_ONLN)

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

#v3.X-rcX + upto SHA
#prev_KERNEL_SHA=""
#KERNEL_SHA=""

#git branch
BRANCH="am33x-v3.8"

DISTRO=cross
DEBARCH=armhf
#
