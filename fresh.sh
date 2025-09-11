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
#   - consider mapping the mac.address and static DHCP lease
#
VMNAME=scratch
IMG=noble-server-cloudimg-amd64.img

NETWORK_ARGS="bridge=br0,model.type=virtio,mac.address=50:54:00:00:00:42"

#
# Script variables
#
SRC_IMG="./${IMG}"
DEST_IMG="/var/local/image/${VMNAME}.img"

#
# Temporary directory and cleanup
#
cleanup() {
  if [ -n "$TMPDIR" ]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT
declare -r TMPDIR=$(mktemp -d)

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
# Set up cloud-init data files
#

# create a new instance_id
instance_id=$(openssl rand -hex 3)

# compress the vm-scripts
vmfs=$(tar -cz -C ./vmfs . | base64 -w 0 | tee vmfs.tgz)

# read the ssh public key
ssh_key=$(cat ssh/service.pub)


# user-data.yaml
cat <<EOF > $TMPDIR/user-data.yaml
## template: jinja
#cloud-config
ssh_authorized_keys: 
  - "$ssh_key"
hostname: ${VMNAME}
write_files:
  - path: /vmfs.tgz
    content: |
      ${vmfs}
    encoding: base64
runcmd:
  - /usr/bin/tar --no-same-owner -C / --owner=root --group=root -xzvf /vmfs.tgz
  - /usr/bin/bash /run/scripts/netplan-override.sh
  - /usr/sbin/shutdown -r now
EOF

# meta-data.yaml
cat <<EOF > $TMPDIR/meta-data.yaml
instance-id: ${instance_id}/${VMNAME}
EOF

# network-config.yaml
cat <<EOF > $TMPDIR/network-config.yaml
EOF

CLOUD_INIT_ARGS="\
user-data=$TMPDIR/user-data.yaml\
,meta-data=$TMPDIR/meta-data.yaml\
,network-config=$TMPDIR/network-config.yaml\
,disable=on"

#
# Copy a fresh image into working directory
#
sudo -u libvirt-qemu -- cp $SRC_IMG $DEST_IMG
sudo -u libvirt-qemu -- chmod 666 $DEST_IMG


#
# Invoke virt-install
#

virsh destroy  $VMNAME 2>/dev/null || true
virsh undefine $VMNAME 2>/dev/null || true

FLAGS=$(cat<<EOF
--name $VMNAME
--connect qemu:///system \
--memory 8192 \
--cpu host-model \
--osinfo ubuntu24.04 \
--import \
--disk path=$DEST_IMG \
--network $NETWORK_ARGS \
--cloud-init $CLOUD_INIT_ARGS
EOF
)

echo ">>> virt-install $FLAGS"
virt-install $FLAGS

