#!/bin/bash

#
# livefs-editor is a required dependency:
#   git clone https://github.com/mwhudson/livefs-editor

#
# Run Startup Disk Creator
#

mkdir -p /var/local/image

SRC_ISO=/var/local/image/ubuntu-24.04.2-live-server-amd64.iso
DEST_ISO=/var/local/image/ubuntu-24.04.2-live-server-amd64-nocloud.iso

PYTHONPATH=./livefs-editor \
python3 -m livefs_edit \
	$SRC_ISO \
	$DEST_ISO \
	--cp $PWD/cloud-init/grub.cfg new/iso/boot/grub/grub.cfg \

chown libvirt-qemu:kvm $DEST_ISO
