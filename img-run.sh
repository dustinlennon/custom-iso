#!/usr/bin/bash

#
# runner:
#	VMNAME=golf sudo -E ./img-run.sh
#

VMNAME=${VMNAME:-scratch}

exec virsh start $VMNAME \
	--console \
	--autodestroy
