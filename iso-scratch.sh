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
virsh net-define mrdlnet.xml
virsh net-start mrdlnet
sudo ip tuntap add dev tapx mode tap vnet_hdr
sudo ip link set tapx master virbr2
sudo ip link set tapx up
EOF

FSPATH=image

source iso-shared.sh

setup

run_kvm \
	-machine pc \
	-cpu 'host' \
	-m 4G \
	-device virtio-scsi-pci \
	-device scsi-hd,drive=myhd \
	-blockdev driver=raw,node-name=myhd,file.driver=file,file.filename=./${FSPATH}/root.img \
	-device virtio-net,mac=50:54:00:00:00:42,netdev=net0 \
	-netdev tap,id=net0,br=virbr2,ifname=tapx,script="/home/dnlennon/Workspace/Sandbox/custom-iso/scripts/scratch-ifup",downscript=no

teardown

