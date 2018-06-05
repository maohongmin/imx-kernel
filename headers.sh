#!/bin/sh -e
DIR=$PWD
mkdir -p ${DIR}/deploy/
CORES=$(getconf _NPROCESSORS_ONLN)

unset CC
. "${DIR}/system.sh"
export CC
echo "CROSS_COMPILE=${CC}"

. ${DIR}/version.sh

make_kernel () {
	if [ "x${KERNEL_ARCH}" = "xarm" ] ; then
		image="zImage"
	else
		image="Image"
	fi

	unset address

	##uImage, if you really really want a uImage, zreladdr needs to be defined on the build line going forward...
	##make sure to install your distro's version of mkimage
	#image="uImage"
	#address="LOADADDR=${ZRELADDR}"

	cd "${DIR}/KERNEL" || exit
	echo "-----------------------------"
	echo "make -j${CORES} ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE=\"${CC}\" ${address} ${image} modules"
	echo "-----------------------------"
	make -j${CORES} ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE="${CC}" ${address} ${image} modules
	echo "-----------------------------"

	if grep -q dtbs "${DIR}/KERNEL/arch/${KERNEL_ARCH}/Makefile"; then
		echo "make -j${CORES} ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE=\"${CC}\" dtbs"
		echo "-----------------------------"
		make -j${CORES} ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE="${CC}" dtbs
		echo "-----------------------------"
	fi

	KERNEL_UTS=$(cat "${DIR}/KERNEL/include/generated/utsrelease.h" | awk '{print $3}' | sed 's/\"//g' )

	if [ -f "${DIR}/deploy/${KERNEL_UTS}.${image}" ] ; then
		rm -rf "${DIR}/deploy/${KERNEL_UTS}.${image}" || true
		rm -rf "${DIR}/deploy/config-${KERNEL_UTS}" || true
	fi

	if [ -f ./arch/${KERNEL_ARCH}/boot/${image} ] ; then
		cp -v arch/${KERNEL_ARCH}/boot/${image} "${DIR}/deploy/${KERNEL_UTS}.${image}"
		cp -v .config "${DIR}/deploy/config-${KERNEL_UTS}"
	fi

	cd "${DIR}/" || exit

	if [ ! -f "${DIR}/deploy/${KERNEL_UTS}.${image}" ] ; then
		export ERROR_MSG="File Generation Failure: [${KERNEL_UTS}.${image}]"
		/bin/sh -e "${DIR}/scripts/error.sh" && { exit 1 ; }
	else
		ls -lh "${DIR}/deploy/${KERNEL_UTS}.${image}"
	fi
}

make_pkg () {
	cd "${DIR}/KERNEL" || exit

	deployfile="-${pkg}.tar.gz"
	tar_options="--create --gzip --file"

	if [ -f "${DIR}/deploy/${KERNEL_UTS}${deployfile}" ] ; then
		rm -rf "${DIR}/deploy/${KERNEL_UTS}${deployfile}" || true
	fi

	if [ -d "${DIR}/deploy/tmp" ] ; then
		rm -rf "${DIR}/deploy/tmp" || true
	fi
	mkdir -p "${DIR}/deploy/tmp"

	echo "-----------------------------"
	echo "Building ${pkg} archive..."

	case "${pkg}" in
	modules)
		make -s ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE="${CC}" modules_install INSTALL_MOD_PATH="${DIR}/deploy/tmp"
		;;
	firmware)
		make -s ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE="${CC}" firmware_install INSTALL_FW_PATH="${DIR}/deploy/tmp"
		;;
	dtbs)
		if grep -q dtbs_install "${DIR}/KERNEL/arch/${KERNEL_ARCH}/Makefile"; then
			make -s ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE="${CC}" dtbs_install INSTALL_DTBS_PATH="${DIR}/deploy/tmp"
		else
			find ./arch/${KERNEL_ARCH}/boot/ -iname "*.dtb" -exec cp -v '{}' "${DIR}/deploy/tmp/" \;
		fi
		;;
	headers)
		make -s ARCH=${KERNEL_ARCH} LOCALVERSION=${BUILD} CROSS_COMPILE="${CC}" headers_install INSTALL_HDR_PATH="${DIR}/deploy/tmp"
		;;
	esac

	echo "Compressing ${KERNEL_UTS}${deployfile}..."
	cd "${DIR}/deploy/tmp" || true
	tar ${tar_options} "../${KERNEL_UTS}${deployfile}" ./*

	cd "${DIR}/" || exit
	rm -rf "${DIR}/deploy/tmp" || true

	if [ ! -f "${DIR}/deploy/${KERNEL_UTS}${deployfile}" ] ; then
		export ERROR_MSG="File Generation Failure: [${KERNEL_UTS}${deployfile}]"
		/bin/sh -e "${DIR}/scripts/error.sh" && { exit 1 ; }
	else
		ls -lh "${DIR}/deploy/${KERNEL_UTS}${deployfile}"
	fi
}

make_modules_pkg () {
	pkg="modules"
	make_pkg
}

make_firmware_pkg () {
	pkg="firmware"
	make_pkg
}

make_dtbs_pkg () {
	pkg="dtbs"
	make_pkg
}

make_headers () {
	pkg="headers"
	make_pkg
}

#make_kernel
#make_modules_pkg
#make_firmware_pkg
KERNEL_UTS=$(cat "${DIR}/KERNEL/include/generated/utsrelease.h" | awk '{print $3}' | sed 's/\"//g' )
make_headers

#if grep -q dtbs "${DIR}/KERNEL/arch/${KERNEL_ARCH}/Makefile"; then
#	make_dtbs_pkg
#fi

echo "-----------------------------"
echo "Script Complete"
echo "${KERNEL_UTS}" > kernel_version
echo "[user@localhost:~$ export kernel_version=${KERNEL_UTS}]"
echo "-----------------------------"
