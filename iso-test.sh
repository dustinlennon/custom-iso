#!/usr/bin/bash

#
# References:
#   - https://man.archlinux.org/man/virt-install.1
#


# source iso-shared.sh
# check_root

VMNAME=isotest

SRC_ISO=/var/local/image/ubuntu-24.04.2-live-server-amd64.iso
DEST_IMG=/var/local/image/ubuntu-24.04.2-live-server-amd64.img

NETWORK_ARGS="bridge=br0,model.type=virtio,mac.address=50:54:00:00:00:43"

#
# Action: create or start
#
if [ -f "$DEST_IMG" ]; then
  read -n 1 -p "erase image [$DEST_IMG] (N/y) " && echo
  if [ "$REPLY" = 'Y' ] || [ "$REPLY" = 'y' ]; then
    sudo -u libvirt-qemu -- rm -rf $DEST_IMG
  else
    exec virsh start $VMNAME \
      --console \
      --autodestroy
  fi
fi

#
# Create image 
#
sudo -u libvirt-qemu -- rm -f $DEST_IMG
sudo -u libvirt-qemu -- qemu-img create -f qcow2 $DEST_IMG 10G

#
# Create image
#
CLOUD_DIR=./cloud-init/preseed
CLOUD_INIT_ARGS="\
user-data=$CLOUD_DIR/user-data.yaml\
,meta-data=$CLOUD_DIR/meta-data.yaml\
"

#
# Invoke virt-install
#

virsh destroy  $VMNAME 2>/dev/null || true
virsh undefine $VMNAME 2>/dev/null || true

FLAGS=$(cat<<EOF
--name $VMNAME \
--connect qemu:///system \
--autoconsole graphical \
--memory 8192 \
--cpu host-model \
--osinfo ubuntu24.04 \
--cdrom $SRC_ISO \
--disk path=$DEST_IMG \
--network $NETWORK_ARGS \
--cloud-init $CLOUD_INIT_ARGS
EOF
)

echo ">>> virt-install $FLAGS"
virt-install $FLAGS



# # setup

# run_kvm \
# 	-machine pc \
# 	-cpu 'host' \
# 	-m 4G \
# 	-device virtio-scsi-pci \
# 	-device scsi-hd,drive=hd \
# 	-blockdev driver=raw,node-name=hd,file.driver=file,file.filename=/var/local/image/${vmname}.img \
# 	-device virtio-net,netdev=n1 \
# 	-netdev bridge,id=n1,br=br0 \
# 	-cdrom $SRC_ISO

# #  original ./iso-install.sh script
# #	 -netdev user,id=unet,hostfwd=tcp::2222-:22 \
# #	 -device virtio-net-pci,netdev=unet \


# # teardown
