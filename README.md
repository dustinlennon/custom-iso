# custom-iso

Create a custom ISO Ubuntu image that works over wireless?  Oddly difficult.  One needs to navigate autoinstall, netplan, and cloud-init configurations.  Using DHCP incurs additional complexity, requiring discovery via multicast dns (mdns).

This solution provides machinery that dynamically generates a netplan configuration as well as supporting systemd-resolved and systemd-network files.  The result is a system accessible via authorized keys, simply `ssh ubuntu@host.local`

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
Then, change the password(s), add a known SSH public key, rename the johndoe account.

```bash
# access_points.yml
cp ./src/access_points.yml.sample ./src/access_points.yml
```
Then, replace the dictionary entries with your ssid-name(s) and password(s).

### generate network-config.sh

'rebuild.py' generates network-config.sh, injecting files from ./src:

```bash
src/rebuild.py
# args="--rootfs ${PWD}/rfs" ./network-config.sh
```

### build scratch.iso

This has been tested with ubuntu-24.04.2-live-server-amd64.iso.  Create a link to this ISO file in the current directory, then:

```bash
# ln $HOME/Data/ISO/ubuntu-24.04.2-live-server-amd64.iso
sudo ./iso-create.sh
```

### test the iso

Use kvm to run the ISO.

```bash
./iso-test.sh
```

### copy to USB

[Startup Disk Creator](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#1-overview) has a simple UI and is likely a good option for getting the ISO to a USB stick.
