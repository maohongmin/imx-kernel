#!/bin/sh -e
DIR=$PWD

DSR=/media/zhe/rootfs

if [ x"$1" = x"" ] ; then
	echo "Not input sd card rootfs dir, use default ${DSR}"
else
	DSR=$1
fi

if [ ! -d ${DSR} ] ; then
	echo "${DSR} not exsit"
	exit 1
fi

. ${DIR}/version.sh

KERNEL_UTS=$(cat ${DIR}/KERNEL/include/generated/utsrelease.h | awk '{print $3}' | sed 's/\"//g' )

untar_pkg () {
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

	sudo mkdir -p ${dst_dir}
	tar_options="xvf"
	if [ -f "${DIR}/deploy/${KERNEL_UTS}${deployfile}" ] ; then
		echo "tar ${tar_options} ${DIR}/deploy/${KERNEL_UTS}${deployfile} -C ${dst_dir}"
		sudo tar ${tar_options} ${DIR}/deploy/${KERNEL_UTS}${deployfile} -C ${dst_dir}
	else
		exit 3
	fi
}

image="zImage"

# kernel
if [ -f "${DIR}/deploy/${KERNEL_UTS}.${image}" ] ; then
	sudo mkdir -p ${DSR}/boot
	sudo cp -v ${DIR}/deploy/${KERNEL_UTS}.${image} ${DSR}/boot/vmlinuz-${KERNEL_UTS}
	# uEnv.txt
	unset older_kernel
	unset location
	if [ -f "${DSR}/boot/uEnv.txt" ] ; then
		location=${DSR}/boot/
	fi
	if [ ! "x${location}" = "x" ] ; then
		older_kernel=$(grep uname_r "${location}/uEnv.txt" | grep -v '#' | awk -F"=" '{print $2}' || true)

		if [ ! "x${older_kernel}" = "x" ] ; then
			if [ ! "x${older_kernel}" = "x${KERNEL_UTS}" ] ; then
				sudo sed -i -e 's:uname_r='${older_kernel}':uname_r='${KERNEL_UTS}':g' "${location}/uEnv.txt"
			fi
			echo "info: /boot/uEnv.txt: `grep uname_r ${location}/uEnv.txt`"
		fi
	else
		echo "File uEnv.txt not exsit"
		sudo sh -c "echo 'uname_r=${KERNEL_UTS}' >> ${DSR}/boot/uEnv.txt"
	fi
else
	echo "File [${KERNEL_UTS}.${image}] not exsit"
	exit 1
fi

# dtb
pkg="dtbs"
untar_pkg

# modules
pkg="modules"
untar_pkg

# firmware
pkg="firmware"
untar_pkg
