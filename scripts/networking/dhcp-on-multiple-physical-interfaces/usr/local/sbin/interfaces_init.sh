#!/bin/sh

# This script is run from rc.local (and only once)

. /usr/local/sbin/networking_defs.sh

rm -rf "$SCRIPTS_LOCKDIR"

# Enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# No other need to specificly handle interfaces,
# /etc/network/interfaces works somewhat in this.
