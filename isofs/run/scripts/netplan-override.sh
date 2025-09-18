#!/usr/bin/bash

#
# Enable mDNS queries:
#   $ resolvectl query --protocol=mdns-ipv4 --cache=no sandbox.local
#

IFACE=$(ip -j route show to default | jq -r '.[0].dev')
NETWORK_FILE="10-netplan-${IFACE}.network"

#
# The drop-in configuration
#
CONFIG=$(cat <<EOF
#
# Ref: man systemd.network
#
[Match]
Name=${IFACE}

[Network]
MulticastDNS=yes
EOF
)

RUN_PATH=/run/systemd/network
ETC_PATH=/etc/systemd/network

if [ -f "/${RUN_PATH}/${NETWORK_FILE}" ]; then
	mkdir -p ${ETC_PATH}/${NETWORK_FILE}.d
	echo "+ adding network drop-in 10-override.conf"
	echo "$CONFIG" | tee ${ETC_PATH}/${NETWORK_FILE}.d/10-override.conf
else
	echo "+ no network drop-in required"
fi
