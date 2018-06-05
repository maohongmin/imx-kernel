#!/bin/sh -e
DIR=$PWD

REMOTE=ubuntu@192.168.1.3
REMOTE_DSR=/home/ubuntu/kernel-deploy
DSR=${REMOTE}:${REMOTE_DSR}
passwd=temppwd

. ${DIR}/version.sh

KERNEL_UTS=$(cat ${DIR}/KERNEL/include/generated/utsrelease.h | awk '{print $3}' | sed 's/\"//g' )

scp_pkg () {
	deployfile="-${pkg}.tar.gz"
	case "${pkg}" in
	modules)
		dst_dir=${DSR}/
		;;
	firmware)
		dst_dir=${DSR}/lib/firmware/
		;;
	dtbs)
		dst_dir=${DSR}/boot/dtbs/${KERNEL_UTS}/
		;;
	esac

	if [ -f "${DIR}/deploy/${KERNEL_UTS}${deployfile}" ] ; then
		echo "scp ${DIR}/deploy/${KERNEL_UTS}${deployfile} -C ${dst_dir}"
		sshpass -p ${passwd} scp -o StrictHostKeyChecking=no ${DIR}/deploy/${KERNEL_UTS}${deployfile} ${DSR}/
	else
		exit 3
	fi
}

image="zImage"
deployfile="-${pkg}.tar.gz"
# kernel
if [ -f "${DIR}/deploy/${KERNEL_UTS}.${image}" ] ; then
	#sudo mkdir -p ${DSR}/boot
	sshpass -p ${passwd} scp -o StrictHostKeyChecking=no ${DIR}/deploy/${KERNEL_UTS}.${image} ${DSR}/
	sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${REMOTE} "echo -n ${KERNEL_UTS} > ${REMOTE_DSR}/version"
	# uEnv.txt
	unset older_kernel
	unset location
else
	echo "File [${KERNEL_UTS}.${image}] not exsit"
	exit 1
fi

# dtb
pkg="dtbs"
scp_pkg

# modules
pkg="modules"
scp_pkg

# firmware
pkg="firmware"
untar_pkg
