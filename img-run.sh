#!/usr/bin/bash

VMNAME=${VMNAME:-scratch}

exec virsh start $VMNAME \
	--console \
	--autodestroy
