# custom-iso

Create a custom ISO Ubuntu image that works over wireless?  Oddly difficult.  One needs to navigate autoinstall, netplan, and cloud-init configurations.  Using DHCP incurs additional complexity, requiring discovery via multicast dns (mdns).

This solution provides machinery that dynamically generates a netplan configuration as well as systemd-network files associated with wifi access points.  The result is a system accessible via authorized keys, simply `ssh ubuntu@example.local`

## up and running

### clone the repo

```bash
git clone https://github.com/dustinlennon/custom-iso
```

### dependencies

Clone livefs-editor directly into the custom-iso directory.

```bash
cd custom-iso
git clone https://github.com/mwhudson/livefs-editor
```

### customize configuration

```bash
# user-data
cp ./cloud-init/preseed/user-data.sample ./cloud-init/preseed/user-data
```

Add a known SSH public key.


### build scratch.iso

This has been tested with ubuntu-24.04.2-live-server-amd64.iso.  Create a link to this ISO file in the current directory, then:

```bash
# ln $HOME/Data/ISO/ubuntu-24.04.2-live-server-amd64.iso
sudo ./iso-create.sh
```

### install the system

Use kvm/qemu to install the system.

```bash
./iso-install.sh
```

This configuration is in "user" mode.  That is, ssh works through port mapping on localhost:

`ssh ansible@localhost -p 2222`

N.B., one will need to be ready to supply the private key.  This could use the `-i` parameter, explicitly.  Alternatively, `ssh-agent` could be used.


### Assigning IP addresses


#### virbr0

libvirt manages a virtual network bridge, "virbr0".  This is defined in an XML file, `/etc/libvirt/qemu/networks/default.xml`.  It exposes the VM to the host at a DHCP-assigned IP address.  This requires an additional discovery step, e.g.:

`resolvectl query -p mdns -i virbr0 --cache=false example.local`

#### virbr1

A preferable alternative would be to assign a known, static IP address.  To accomplish this,  create a second virtual network bridge, "virbr1".  Note that the MAC address here matches the one in the `./iso-run.sh` script.

```
<!-- /etc/libvirt/qemu/networks/static-vm.xml -->
<network>
  <name>vmnode</name>
  <uuid>58660534-366a-4baf-8938-fdfab60f1399</uuid>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:bd:56:46'/>
  <ip address='192.168.206.128' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.206.2' end='192.168.206.254'/>
      <host mac='50:54:00:00:00:42' name='example' ip='192.168.206.11'/>
    </dhcp>
  </ip>
</network>
```

+ XML reference [https://libvirt.org/formatnetwork.html](https://libvirt.org/formatnetwork.html)
+ libvirt Networking Handbook [https://jamielinux.com/docs/libvirt-networking-handbook/](https://jamielinux.com/docs/libvirt-networking-handbook/)


Then, use `virsh` to install:

```bash
virsh net-define static-vm.xml
virsh net-start static-vm
virsh net-autostart static-vm
```

#### ACL permissions

It may also be necessary to create the `/etc/qemu/bridges.conf` whitelist for kvm/qemu:

```
allow virbr0
allow virbr1
```


### run the VM

Use kvm/qemu to run the ISO.

```bash
./iso-run.sh
```

## USB devices

[Startup Disk Creator](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#1-overview) has a simple UI and is likely a good option for getting the ISO to a USB stick.
