
custom-iso
====

This repo aims to provide a simple process for producing VMs and ISOs that are ready for ansible.


Quickstart
----

This framework requires that the install server -- `install-server.sh` -- be available.

```bash
# install dependencies
pipenv install

# create the tkap user:group, /run/tkap, /var/lib/tkap directories
sudo -E pipenv run installer --install

# run the installation server
sudo -E pipenv run twistd -ny $(pipenv run installer)/resources/examples/tkap.tac
```

Check that the installion server is up and running.  Compare with the corresponding entry in config.yaml.

```
$ curl -s http://localhost/sshkeys/ubuntu
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLqmmfByjFuStwUpyIc7dcn2nOV/q+LDTzAn/32zbc/ service@carolina
```

### Certs for HTTPS

Next, check that the CA / certificates are correctly installed so as to enable HTTPS.

```
$ curl -s https://192.168.1.104/sshkeys/ubuntu
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLqmmfByjFuStwUpyIc7dcn2nOV/q+LDTzAn/32zbc/ service@carolina
```

Under the hood, the CA file is shared with the guest via `cloud-init/preseed/user-data-img.yaml` as a trusted item in `ca_certs`.  The trusted CA signs a certificate request from the host, used by the installation server via `cert_pem_path` in the `.env.tkap` file.  This can be verified:

```
$ openssl verify -CAfile mrdl.crt carolina.pem
carolina.pem: OK
```

where `mrdl.crt` is the CA certificate; and `carolina.pem` is the aforementioned, signed CSR.



Images
----

The run order of the scripts is:

```bash
prep-iso.sh
img-base.sh
img-run.sh
```

*Note, the scripts operate on files in /var/local/image.*


### `prep-iso.sh`

Modifies a stock ISO with a "nocloud-net" datasource that utilizes the installation server.

### `img-base.sh`

Creates a QCOW2 image from the nocloud ISO.  This injects a trusted CA; runs ssh-import-id over HTTPS; and sets the hostname, if one is known from the DHCP server.


### `img-run.sh`

Start the VM.


ISOs
----

### iso-base.sh

TBD