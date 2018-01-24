#!/bin/sh -e
DIR=$PWD
mkdir -p ${DIR}/deploy/

unset CC
. "${DIR}/system.sh"
export CC
echo "CROSS_COMPILE=${CC}"

. "${DIR}/version.sh"

make_clean () {
	cd "${DIR}/KERNEL" || exit
#	cp -v ${DIR}/patches/defconfig .config
	make ARCH=${KERNEL_ARCH} CROSS_COMPILE="${CC}" clean
	cd "${DIR}/" || exit
}

make_clean

echo "-----------------------------"
echo "Script Complete"
echo "${KERNEL_UTS}" > kernel_version
echo "[user@localhost:~$ export kernel_version=${KERNEL_UTS}]"
echo "-----------------------------"
