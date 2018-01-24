#!/bin/sh -e
DIR=$PWD
mkdir -p ${DIR}/deploy/

unset CC
. "${DIR}/system.sh"
export CC
echo "CROSS_COMPILE=${CC}"

. "${DIR}/version.sh"

make_menuconfig () {
	cd "${DIR}/KERNEL" || exit
	cp -v ${DIR}/patches/defconfig .config
	make ARCH=${KERNEL_ARCH} CROSS_COMPILE="${CC}" menuconfig
	cp -v .config "${DIR}/patches/defconfig"
	cd "${DIR}/" || exit
	KERNEL_UTS=$(cat "${DIR}/KERNEL/include/generated/utsrelease.h" | awk '{print $3}' | sed 's/\"//g' )
}

make_menuconfig

echo "-----------------------------"
echo "Script Complete"
echo "${KERNEL_UTS}" > kernel_version
echo "[user@localhost:~$ export kernel_version=${KERNEL_UTS}]"
echo "-----------------------------"
