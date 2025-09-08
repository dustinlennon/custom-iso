#!/usr/bin/bash


# N.B., post-install edits
#
# # /etc/netplan/50-cloud-init.yaml
# network:
#   version: 2
#   ethernets:
#     ens1:
#       match:
#         macaddress: 50:54:00:00:00:42
#       optional: true
#       dhcp4: true
#       link-local:
#       - ipv4

# N.B., virt-viewer
# $ virt-viewer ubuntu24.04



VIRSH_RESET=${VIRSH_RESET:=}

#
# Create mrdlnet
#

virsh net-list --all | grep -q "mrdlnet"
known_network=$?

if [ "$known_network" == "0" ]; then
	virsh net-destroy mrdlnet
	virsh net-undefine mrdlnet
fi

# # define the mrdlnet network (virtual bridge)
# cat <<-EOF | tee /tmp/net.xml
# <network>
# 	<name>mrdlnet</name>
# 	<forward mode='route'/>
# 	<bridge name='virbr2' stp='on' delay='0'/>
# 	<mac address='52:54:00:bd:56:45'/>
# 	<ip address='192.168.2.60' netmask='255.255.255.252'>
# 		<dhcp>
# 			<range start='192.168.2.61' end='192.168.2.62'/>
# 			<host mac='50:54:00:00:00:42' name='scratch' ip='192.168.2.62'/>
# 		</dhcp>
# 	</ip>
# </network>
# EOF

# define the mrdlnet network (bridge)
cat <<-EOF | tee /tmp/net.xml
<network>
	<name>mrdlnet</name>
	<forward mode='bridge'/>
	<bridge name='br0'/>
</network>
EOF


virsh net-create /tmp/net.xml --validate

#
# Import into virsh (n.b., /var/local/image/root.img)
#

if [ "$VIRSH_RESET" != "" ]; then

	virsh list --all | grep -q "ubuntu24\.04"
	known_vm=$?

	if [ "$known_vm" == "0" ]; then
		virsh shutdown ubuntu24.04 > /dev/null 2>&1 || true
		virsh undefine ubuntu24.04 > /dev/null 2>&1  || true
	fi

	sudo virt-install \
		--connect qemu:///system \
		--memory=4096 \
		--import \
		--osinfo ubuntu24.04 \
		--disk /var/local/image/root.img,format=raw \
		--network network=mrdlnet,model.type=virtio,mac.address=50:54:00:00:00:42 \
		--noreboot --noautoconsole
fi


#
# start vm
# 
cleanup() {
	virsh shutdown ubuntu24.04
}
trap cleanup EXIT

virsh start ubuntu24.04 --console




