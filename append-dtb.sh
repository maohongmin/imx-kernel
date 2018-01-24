#!/bin/sh

DIR=$PWD
DTBNAME=am335x-agv.dtb

. ${DIR}/version.sh
KERNEL_UTS=$(cat ${DIR}/KERNEL/include/generated/utsrelease.h | awk '{print $3}' | sed 's/\"//g' )

image="zImage"

if [ -f ${DIR}/KERNEL/arch/arm/boot/dts/${DTBNAME} ]; then
	echo "append dts to kernel... "
	cat ${DIR}/KERNEL/arch/arm/boot/dts/${DTBNAME} > ${DIR}/deploy/${KERNEL_UTS}.${image}
	echo "done"
fi

