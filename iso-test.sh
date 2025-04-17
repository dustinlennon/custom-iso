#!/usr/bin/bash

#
# Ref: https://www.qemu.org/docs/master/system/introduction.html
#
# access:
# 	ssh ubuntu@localhost -p 2222
#

stty -echoctl

sigint_handler() {
	echo "caught ctrl-c"
	trap - SIGINT
}
trap sigint_handler SIGINT

ISO_PATH=scratch.iso

if [ ! -d ramdisk ]; then
	mkdir ramdisk
	sudo mount -t tmpfs -o size=8000M kvmroot ./ramdisk
	touch ./ramdisk/root.img
	truncate -s 7800M ./ramdisk/root.img
fi

kvm \
	-machine pc \
	-cpu 'host' \
	-m 4G \
	-device virtio-scsi-pci \
	-device scsi-hd,drive=hd \
	-blockdev driver=raw,node-name=hd,file.driver=file,file.filename=./ramdisk/root.img \
	-device virtio-net-pci,netdev=unet \
	-netdev user,id=unet,hostfwd=tcp::2222-:22 \
	-cdrom $ISO_PATH 2> /dev/null &

pid=$!
echo $pid > kvm.pid
wait -p KVM_EC $pid
exit_status=$?

rm -f kvm.pid
stty echoctl

# prompt for cleanup
read -n 1 -p 'erase ramdisk (N/y) ' && echo
if [ "$REPLY" = 'Y' ] || [ "$REPLY" = 'y' ]; then
	sudo umount ./ramdisk
	rmdir ramdisk	
fi

>&2 echo "exiting kvm.sh"

