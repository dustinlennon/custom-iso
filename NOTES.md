
Mount and ISO
----

```bash
sudo mount -o loop,ro image/ubuntu-24.04.2-live-server-amd64.iso ./mnt
```

Mount an IMG
----

```bash
sudo guestmount \
  -a image/ubuntu-24.04.2-live-server-amd64.img \
  -i --ro -o allow_other \
  mnt

sudo guestunmount mnt
```


Export 99-installer.cfg from IMG
----

```bash
sudo guestfish -i --ro \
  -a image/ubuntu-24.04.2-live-server-amd64.img \
  copy-out /etc/cloud/cloud.cfg.d/99-installer.cfg .
sudo chown $USER:$USER 99-installer.cfg
```

