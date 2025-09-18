#!/bin/bash

scripts=(
	"/run/scripts/netplan-override.sh"
	"/run/scripts/restart-networking.sh"
)

for s in ${scripts[@]}; do
	if [ -f $s ]; then
		printf "\n$s:\n"
		/bin/bash "$s" 2>&1 | sed 's/^/  /' 
	fi
done
