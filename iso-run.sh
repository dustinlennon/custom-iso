#!/usr/bin/bash

#
# Ref: https://www.qemu.org/docs/master/system/introduction.html
#
# access:
# 	ssh ansible@192.168.206.11 
#

source iso-shared.sh

setup

run_kvm \
	-machine pc \
	-cpu 'host' \
	-m 4G \
	-device virtio-scsi-pci \
	-device scsi-hd,drive=myhd \
	-blockdev driver=raw,node-name=myhd,file.driver=file,file.filename=./ramdisk/root.img \
	-device virtio-net,mac=50:54:00:00:00:42,netdev=mybr \
	-netdev bridge,id=mybr,br=virbr1


teardown

