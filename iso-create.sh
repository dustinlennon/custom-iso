#!/bin/bash

#
# Create scratch.iso.  Run as sudo.
#
# livefs-editor is a required dependency:
#   git clone https://github.com/mwhudson/livefs-editor
#
# Alternatively, kernel parameters could be specified via livefs_edit:
#   --add-cmdline-arg 'hostname=hal ds=nocloud\;s=/cdrom/preseed'
#

if [ "$USER" != "root" ]; then
	>&2 echo ">>> error: run script as root"
	exit 1
fi

CONFIG_PATH=$PWD/cloud-init
SRCISO=$PWD/ubuntu-24.04.2-live-server-amd64.iso

PYTHONPATH=./livefs-editor \
python3 -m livefs_edit \
	$SRCISO \
	scratch.iso \
	--shell 'mkdir -p new/iso/preseed' \
	--cp $PWD/network-config.sh new/iso/network-config.sh \
	--cp $CONFIG_PATH/boot/grub/grub.cfg new/iso/boot/grub/grub.cfg \
	--cp $CONFIG_PATH/preseed/meta-data new/iso/preseed/meta-data \
	--cp $CONFIG_PATH/preseed/user-data new/iso/preseed/user-data \
	--cp $CONFIG_PATH/preseed/vendor-data new/iso/preseed/vendor-data	

chown dnlennon:dnlennon scratch.iso