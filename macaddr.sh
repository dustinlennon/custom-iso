#!/usr/bin/bash

source shared/macaddr

if [ $# -eq 1 ]; then
	macaddr $1
fi

