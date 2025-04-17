#!/bin/bash

cwd=$PWD
pushd $HOME/tmp/subiquity
SNAP=. \
	./scripts/validate-autoinstall-user-data.py \
	${cwd}/cloud-init/preseed/user-data \
	--no-expect-cloudconfig
popd