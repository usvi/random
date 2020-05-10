#!/bin/sh

# This script is run from rc.local (and only once)

. /usr/local/sbin/networking_defs.sh

rmdir $SCRIPTS_LOCKDIR

# Create the virtual interfaces
ifconfig $IF_VIRTUAL_BASE up promisc
ip link add link $IF_VIRTUAL_BASE address 00:90:0b:ff:10:5b $IF_PUB0 type macvlan
ip link set $IF_PUB0 up
ip link add link $IF_VIRTUAL_BASE address 00:90:0b:ff:11:5b $IF_PUB1 type macvlan
ip link set $IF_PUB1 up
ip link add link $IF_VIRTUAL_BASE address 00:90:0b:ff:12:5b $IF_PUB2 type macvlan
ip link set $IF_PUB2 up
