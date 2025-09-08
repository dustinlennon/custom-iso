#!/usr/bin/bash

#
#  Using `-netdev tap` with a wifi is a bit tricky.  This documentation was helpful:
#
#    + https://wiki.debian.org/BridgeNetworkConnections#Bridging_with_a_wireless_NIC
#    + https://jamielinux.com/docs/libvirt-networking-handbook/routed-network.html
#
#
#  An attempt:
#
#  	On router, add a static route:  map 192.168.2.60/4 to gateway 192.168.2.104.  Note,
#   that this must be a different network address space than 192.168.1.0/24, our usual
#   one.
#
#   Create the virbr2 bridge associated with the VM network, e.g. 192.168.2.60/4.  Note
#   that 192.168.2.60 is the network address; 192.168.2.63, the broadcast address.  So
#   only 192.168.2.61 and 192.168.2.62 are available for VMs in this configuration.
#
#   <-- /etc/libvirt/qemu/network/mrdlnet.xml -->
#	<network>
#	<name>mrdlnet</name>
#	<uuid>113ade99-2453-482f-b27e-bd887e56d650</uuid>
#	<forward mode='route'/>
#	<bridge name='virbr2' stp='on' delay='0'/>
#	<mac address='52:54:00:68:a9:dc'/>
#	<ip address='192.168.2.60' netmask='255.255.255.252'>
#		<dhcp>
#		<range start='192.168.2.61' end='192.168.2.62'/>
#		<host mac='50:54:00:00:00:42' name='example' ip='192.168.2.62'/>
#		</dhcp>
#	</ip>
#	</network>
#
#   Add the libvirt network and the tap device (copy and paste)
#

<<EOF
#
# create a LAN-visible, macvtap device
#   N.B., this seems to fail w/ guest not picking up an IP address;
#   however, it may be more likely caused by macvtap bridge mode not
#   moving packets off-host.
#

sudo ip link add \
	link wlp0s20f3 \
	name myvtap \
	type macvtap \
	mode bridge

sudo ip link set myvtap \
	address 52:54:00:68:a9:dc \
	up

sudo ip address \
	add 192.168.1.80/32 \
	dev myvtap
EOF


<<EOF
#
# create a network bridge
#   N.B., this fails b/c wlp0s20f3 "does not allow enslaving to a bridge"
#

sudo ip link add name br0 type bridge
sudo ip link set dev br0 up
sudo ip address add 192.168.1.104/24 dev br0
sudo ip route append default via 192.168.1.1 dev br0

sudo ip link set wlp0s20f3 master br0
sudo ip address del 192.168.1.104/24 dev wlp0s20f3
EOF

#   bridges:
#     br0:
#       interfaces: [ enp4s0 ]
#       dhcp4: no
#       addresses: [192.168.2.15/24]
#       gateway4: 192.168.2.1
#       nameservers:
#         addresses: [1.1.1.1]
#       dhcp6: no
#       link-local: [ ]
#       parameters:
#         stp: true
#         forward-delay: 4


virsh net-list | grep -q "mrdlnet"
known_network=$?

if [ "$known_network" == "0" ]; then
	virsh net-destroy mrdlnet
fi

# define the network
cat <<-EOF | tee /tmp/net.xml
<network>
	<name>mrdlnet</name>
	<forward mode='open'/>
	<bridge name='virbr2' stp='on' delay='0'/>
	<mac address='52:54:00:bd:56:45'/>
	<ip address='192.168.2.60' netmask='255.255.255.252'>
		<dhcp>
			<range start='192.168.2.61' end='192.168.2.62'/>
			<host mac='50:54:00:00:00:42' name='example' ip='192.168.2.62'/>
		</dhcp>
	</ip>
</network>
EOF

virsh net-create /tmp/net.xml --validate

exit 0

# cleanup () {
# 	virsh net-destroy mrdlnet
# }
# trap cleanup EXIT

FSPATH=image

source iso-shared.sh

setup

run_kvm \
	-machine pc-q35-noble \
	-cpu host \
	-m 4G \
	-device virtio-blk,drive=myhd \
	-blockdev driver=raw,node-name=myhd,file.driver=file,file.filename=./${FSPATH}/root.img \
	-device virtio-net,mac=50:54:00:00:00:42,netdev=net0 \
	-netdev tap,id=net0,ifname=macvtap0,script=no,downscript=no

teardown

