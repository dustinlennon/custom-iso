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

source iso-shared.sh

check_root

# rebuild network-config.sh
sudo -u $SUDO_USER python3 src/create_script.py

SRCISO=$PWD/ubuntu-24.04.2-live-server-amd64.iso

PYTHONPATH=./livefs-editor \
python3 -m livefs_edit \
	$SRCISO \
	scratch.iso \
	--shell 'mkdir -p new/iso/preseed' \
	--cp $PWD/network-config.sh              new/iso/network-config.sh \
	--cp $PWD/cloud-init/boot/grub/grub.cfg  new/iso/boot/grub/grub.cfg \
	--cp $PWD/cloud-init/preseed/meta-data   new/iso/preseed/meta-data \
	--cp $PWD/cloud-init/preseed/user-data   new/iso/preseed/user-data \
	--cp $PWD/cloud-init/preseed/vendor-data new/iso/preseed/vendor-data	

chown ${SUDO_USER}:${SUDO_USER} scratch.iso