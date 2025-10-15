
The Scripts
====

The scripts operate on files in /var/local/image.  


Images
----

The run order is:

```bash
img-base.sh
img-update.sh
img-run.sh
```


### `img-base.sh`

Takes an ISO file and creates an IMG.  The IMG is "cloud-init-ready"; that is, the autoinstall process of the ISO has finished its first stage.


### `img-update.sh`

Takes a "cloud-init-ready" IMG, sets a MAC address, and injects an /etc/hostname file.  Outputs an updated IMG.


### `img-run.sh`

Start the VM.


ISOs
----

### iso-base.sh

TBD