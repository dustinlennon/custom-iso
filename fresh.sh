#!/usr/bin/bash

#
# Image URL:
#   https://cloud-images.ubuntu.com/
#	https://cloud-images.ubuntu.com/noble/20250805/noble-server-cloudimg-amd64.img
#

#
# SSH:
#	ssh -i ssh/foo ubuntu@192.168.1.99
#   ssh-add ssh/foo
#   ssh -o StrictHostKeyChecking=no ubuntu@scratch sudo shutdown -h now
#

#
# resize image:
#	qemu-img resize noble-server-cloudimg-amd64.img +10G
#   qemu-img info noble-server-cloudimg-amd64.img
#

IMG=noble-server-cloudimg-amd64.img
SRC_IMG="./${IMG}"
DEST_IMG="/var/local/image/${IMG}"
SSH_PUBKEY=./ssh/foo.pub
USER_DATA=./vconf/user-data.yaml
META_DATA=./vconf/meta-data.yaml

#
# Create or start
#
if [ -f "$DEST_IMG" ]; then
	read -n 1 -p 'erase image (N/y) ' && echo
	if [ "$REPLY" = 'Y' ] || [ "$REPLY" = 'y' ]; then
		sudo -u libvirt-qemu -- rm -rf $DEST_IMG
	else
		exec virsh start ubuntu24.04 \
			--console \
			--autodestroy
	fi
fi

#
# Copy a fresh image into working directory
#
sudo -u libvirt-qemu -- cp $SRC_IMG $DEST_IMG
sudo -u libvirt-qemu -- chmod 666 $DEST_IMG

#
# Invoke virt-install
#

virsh destroy  ubuntu24.04 2>/dev/null || true
virsh undefine ubuntu24.04 2>/dev/null || true

FLAGS=$(cat<<EOF
--connect qemu:///system \
--memory 8192 \
--cpu host-model \
--osinfo ubuntu24.04 \
--import \
--disk path=$DEST_IMG \
--network bridge=br0,model.type=virtio,mac.address=50:54:00:00:00:42 \
--cloud-init user-data=${USER_DATA},meta-data=${META_DATA},disable=on
EOF
)


# --cloud-init clouduser-ssh-key=${SSH_PUBKEY},disable=on

echo ">>> virt-install $FLAGS"
virt-install $FLAGS
