#!/usr/bin/bash

services=(
	systemd-networkd
	systemd-resolved
)

ischroot
if [ $? -eq 0 ]; then
	echo "+ running in chroot"
	exit 0
fi

echo "+ daemon reload"
systemctl daemon-reload

for service in ${services[@]}; do
	systemctl is-active --quiet $service
	if [ $? -eq 0 ]; then
		echo "+ restarting $service"
		systemctl restart $service
	fi
done
