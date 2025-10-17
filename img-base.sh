#!/usr/bin/bash

#
# References:
#   - https://man.archlinux.org/man/virt-install.1
#

VMNAME=${VMNAME:-scratch}

source shared/macaddr
NETWORK_ARGS="bridge=br0,model.type=virtio,mac.address=$(macaddr $VMNAME)"

SRC_ISO=/var/local/image/ubuntu-24.04.2-live-server-amd64-nocloud.iso
DEST_IMG="/var/local/image/${VMNAME}.img"

#
# Clobber check
#
if [ -f "$DEST_IMG" ]; then
  read -n 1 -p "erase image [$DEST_IMG] (N/y) " && echo
  if [ "$REPLY" = 'Y' ] || [ "$REPLY" = 'y' ]; then
    sudo -u libvirt-qemu -- rm -rf $DEST_IMG
  else
	exit 0
  fi
fi

#
# Create disk image 
#
sudo -u libvirt-qemu -- rm -f $DEST_IMG
sudo -u libvirt-qemu -- qemu-img create -f qcow2 $DEST_IMG 10G

#
# Invoke virt-install
#
virsh destroy  $VMNAME 2>/dev/null || true
virsh undefine $VMNAME 2>/dev/null || true

FLAGS=$(cat<<EOF
--name $VMNAME
--connect qemu:///system
--autoconsole graphical
--memory 8192
--cpu host-model
--osinfo ubuntu24.04
--cdrom $SRC_ISO
--disk path=$DEST_IMG
--network $NETWORK_ARGS
EOF
)

echo ">>> virt-install $FLAGS"
virt-install $FLAGS
