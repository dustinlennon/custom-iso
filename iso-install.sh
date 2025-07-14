#!/usr/bin/bash

#
# Ref: https://www.qemu.org/docs/master/system/introduction.html
#
# access:
# 	ssh ubuntu@localhost -p 2222 -i mrdl_ubuntu
#

source iso-shared.sh

setup

run_kvm \
	-machine pc \
	-cpu 'host' \
	-m 4G \
	-device virtio-scsi-pci \
	-device scsi-hd,drive=hd \
	-blockdev driver=raw,node-name=hd,file.driver=file,file.filename=./ramdisk/root.img \
	-netdev user,id=unet,hostfwd=tcp::2222-:22 \
	-device virtio-net-pci,netdev=unet \
	-cdrom scratch.iso 2> /dev/null &

teardown