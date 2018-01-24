#!/bin/sh -e
DIR=$PWD
mkdir -p ${DIR}/deploy/
unset CC
CC=/home/zhe/am335x/gcc-linaro-arm-linux-gnueabihf-4.9/bin/arm-linux-gnueabihf-
export CC
echo "CROSS_COMPILE=${CC}"

. ${DIR}/version.sh

make_kernel () {
	image="zImage"
	unset address

	#uImage, if you really really want a uImage, zreladdr needs to be defined on the build line going forward...
	#image="uImage"
	#address="LOADADDR=${ZRELADDR}"

	cd ${DIR}/KERNEL/
	echo "-----------------------------"
	echo "make -j${CORES} ARCH=arm LOCALVERSION=-${BUILD} CROSS_COMPILE="${CC}" ${address} ${image} modules"
	echo "-----------------------------"
	make -j${CORES} ARCH=arm LOCALVERSION=-${BUILD} CROSS_COMPILE="${CC}" ${address} ${image} modules

	unset DTBS
	cat ${DIR}/KERNEL/arch/arm/Makefile | grep "dtbs:" >/dev/null 2>&1 && DTBS=enable

	#FIXME: Starting with v3.15-rc0
	unset has_dtbs_install
	if [ "x${DTBS}" = "x" ] ; then
		cat ${DIR}/KERNEL/arch/arm/Makefile | grep "dtbs dtbs_install:" >/dev/null 2>&1 && DTBS=enable
		if [ "x${DTBS}" = "xenable" ] ; then
			has_dtbs_install=enable
		fi
	fi

	if [ "x${DTBS}" = "xenable" ] ; then
		echo "-----------------------------"
		echo "make -j${CORES} ARCH=arm LOCALVERSION=-${BUILD} CROSS_COMPILE="${CC}" dtbs"
		echo "-----------------------------"
		make -j${CORES} ARCH=arm LOCALVERSION=-${BUILD} CROSS_COMPILE="${CC}" dtbs
		ls arch/arm/boot/* | grep dtb >/dev/null 2>&1 || unset DTBS
	fi

	KERNEL_UTS=$(cat ${DIR}/KERNEL/include/generated/utsrelease.h | awk '{print $3}' | sed 's/\"//g' )

	if [ -f "${DIR}/deploy/${KERNEL_UTS}.${image}" ] ; then
		rm -rf "${DIR}/deploy/${KERNEL_UTS}.${image}" || true
		rm -rf "${DIR}/deploy/config-${KERNEL_UTS}" || true
	fi

	if [ -f ./arch/arm/boot/${image} ] ; then
		if [ ${AUTO_TESTER} ] ; then
			mkdir -p "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/" || true
			cp -uv arch/arm/boot/${image} "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/${KERNEL_UTS}.${image}"
			xz -z "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/${KERNEL_UTS}.${image}"
			mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n ${KERNEL_UTS} -d arch/arm/boot/zImage "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/${KERNEL_UTS}.uImage"
			xz -z "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/${KERNEL_UTS}.uImage"
			cp -uv .config "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/config-${KERNEL_UTS}"
		fi
		cp -v arch/arm/boot/${image} "${DIR}/deploy/${KERNEL_UTS}.${image}"
		cp -v .config "${DIR}/deploy/config-${KERNEL_UTS}"
	fi

	cd ${DIR}/

	if [ ! -f "${DIR}/deploy/${KERNEL_UTS}.${image}" ] ; then
		echo "File Generation Failure: [${KERNEL_UTS}.${image}]"
		exit 1;
		#export ERROR_MSG="File Generation Failure: [${KERNEL_UTS}.${image}]"
		#/bin/sh -e "${DIR}/scripts/error.sh" && { exit 1 ; }
	else
		ls -lh "${DIR}/deploy/${KERNEL_UTS}.${image}"
	fi
}

make_pkg () {
	cd ${DIR}/KERNEL/

	deployfile="-${pkg}.tar.gz"
	tar_options="--create --gzip --file"

	if [ "${AUTO_TESTER}" ] ; then
		#FIXME: xz might not be available everywhere...
		#FIXME: ./tools/install_kernel.sh needs update...
		deployfile="-${pkg}.tar.xz"
		tar_options="--create --xz --file"
	fi

	if [ -f "${DIR}/deploy/${KERNEL_UTS}${deployfile}" ] ; then
		rm -rf "${DIR}/deploy/${KERNEL_UTS}${deployfile}" || true
	fi

	if [ -d ${DIR}/deploy/tmp ] ; then
		rm -rf ${DIR}/deploy/tmp || true
	fi
	mkdir -p ${DIR}/deploy/tmp

	echo "-----------------------------"
	echo "Building ${pkg} archive..."

	case "${pkg}" in
	modules)
		make -s ARCH=arm CROSS_COMPILE="${CC}" modules_install INSTALL_MOD_PATH=${DIR}/deploy/tmp
		;;
	firmware)
		make -s ARCH=arm CROSS_COMPILE="${CC}" firmware_install INSTALL_FW_PATH=${DIR}/deploy/tmp
		;;
	dtbs)
		if [ "x${has_dtbs_install}" = "xenable" ] ; then
			make -s ARCH=arm LOCALVERSION=-${BUILD} CROSS_COMPILE="${CC}" dtbs_install INSTALL_DTBS_PATH=${DIR}/deploy/tmp
		else
			find ./arch/arm/boot/ -iname "*.dtb" -exec cp -v '{}' ${DIR}/deploy/tmp/ \;
		fi
		;;
	esac

	echo "Compressing ${KERNEL_UTS}${deployfile}..."
	cd ${DIR}/deploy/tmp
	tar ${tar_options} ../${KERNEL_UTS}${deployfile} *

	if [ ${AUTO_TESTER} ] ; then
		cp -uv ../${KERNEL_UTS}${deployfile} "${DIR}/deploy/beagleboard.org/${KERNEL_UTS}/"
	fi

	cd ${DIR}/
	rm -rf ${DIR}/deploy/tmp || true

	if [ ! -f "${DIR}/deploy/${KERNEL_UTS}${deployfile}" ] ; then
		echo "File Generation Failure: [${KERNEL_UTS}${deployfile}]"
		exit 2
		#export ERROR_MSG="File Generation Failure: [${KERNEL_UTS}${deployfile}]"
		#/bin/sh -e "${DIR}/scripts/error.sh" && { exit 1 ; }
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


make_kernel
make_modules_pkg
make_firmware_pkg

if [ "x${DTBS}" = "xenable" ] ; then
	make_dtbs_pkg
fi

