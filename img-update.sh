#!/usr/bin/bash

#
# References:
#   - https://man.archlinux.org/man/virt-install.1
#   - https://docs.openstack.org/image-guide/modify-images.html#guestmount
#   - https://cloudinit.readthedocs.io/en/latest/reference/index.html
#

#
# Image URL:
#   https://cloud-images.ubuntu.com/
#	https://cloud-images.ubuntu.com/noble/20250805/noble-server-cloudimg-amd64.img
#

#
# SSH:
#	ssh -i ssh/service ubuntu@192.168.1.99
#   ssh-add ssh/service
#   ssh -o StrictHostKeyChecking=no ubuntu@scratch sudo shutdown -h now
#

#
# resize image:
#	qemu-img resize noble-server-cloudimg-amd64.img +10G
#   qemu-img info noble-server-cloudimg-amd64.img
#

#
# User-defined variables
#
VMNAME=${VMNAME:-scratch}

#
# produce a fixed MAC address, N.B.:
#   - prefix will be 50:54:00 on the guest; D8:0D:17 on the host
#
macaddr() {
	local cmd=$"echo $VMNAME | md5sum | cut -c 1-6 | sed 's/../&:/g; s/:$//'"
	local suffix=$(eval $cmd)
	echo "50:54:00:$suffix"
}

NETWORK_ARGS="bridge=br0,model.type=virtio,mac.address=$(macaddr)"

SRC_IMG=/var/local/image/ubuntu-24.04.2-live-server-amd64.img
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
# remove existing vm
#
virsh destroy  $VMNAME 2>/dev/null || true
virsh undefine $VMNAME 2>/dev/null || true

#
# create copy of src image
#
sudo -u libvirt-qemu -- cp $SRC_IMG $DEST_IMG
sudo -u libvirt-qemu -- chmod 666 $DEST_IMG

#
# Set the hostname (guestfish hack)
#
guestfish <<_EOF_
add ${DEST_IMG}
run
mount /dev/ubuntu-vg/ubuntu-lv /
write /etc/hostname "${VMNAME}"
_EOF_

#
# virt-install import
#
FLAGS=$(cat<<EOF
--name $VMNAME
--autoconsole text
--connect qemu:///system
--memory 8192
--cpu host-model
--osinfo ubuntu24.04
--import
--disk path=$DEST_IMG
--network $NETWORK_ARGS
EOF
)

echo ">>> virt-install $FLAGS"
virt-install $FLAGS

