
Mount an IMG
----

```bash
sudo guestmount \
  -a image/ubuntu-24.04.2-live-server-amd64.img \
  -i --ro -o allow_other \
  mnt

sudo guestunmount mnt
```
