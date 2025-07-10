#!/usr/bin/bash

#
# Ref: https://www.qemu.org/docs/master/system/introduction.html
#
# access:
# 	ssh ansible@192.168.206.11 
#

source iso-shared.sh

# The following works when using virbr0, a bridge created and removed, resp, by virsh:
#   virsh net-start default
#   virsh net-destroy default
# N.B., net-undefine will remove the xml file, too.
#
# The configuration for "default" is located at
#   /etc/libvirt/qemu/networks/default.xml
# and for "vmserver", at,
#   /etc/libvirt/qemu/networks/vmserver.xml
# [Ref](https://libvirt.org/formatnetwork.html)
#
# Use virsh net-* commands, e.g.:
#   virsh net-autostart vmserver
#
# kvm/qemu utilizes dnsmasq, NAT, and DHCP.  With "default", to find the assigned 
# IP address, e.g.:
#   resolvectl query -p mdns -i virbr1 --cache=false hal.local
# 
# With "vmserver", the guest address is static, 192.168.206.11; that is, 
#   ssh ansible@192.168.206.11 
# should work if the VM is up and using virbr1.

setup

run_kvm \
	-machine pc \
	-cpu 'host' \
	-m 4G \
	-device virtio-scsi-pci \
	-device scsi-hd,drive=myhd \
	-blockdev driver=raw,node-name=myhd,file.driver=file,file.filename=./ramdisk/root.img \
	-device virtio-net,mac=50:54:00:00:00:42,netdev=mybr \
	-netdev bridge,id=mybr,br=virbr1


teardown

