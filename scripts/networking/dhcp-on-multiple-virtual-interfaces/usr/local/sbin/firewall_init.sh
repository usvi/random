#!/bin/sh

# This script is run from rc.local (and only once)

. /usr/local/sbin/networking_defs.sh

# Flush chains
/sbin/iptables -F
/sbin/iptables -X
/sbin/iptables -t nat -F
/sbin/iptables -t nat -X

# Drop everything by default
/sbin/iptables -P INPUT DROP
/sbin/iptables -P FORWARD DROP

# Allow outputs
/sbin/iptables -P OUTPUT ACCEPT
# Allow all on localhost
/sbin/iptables -A INPUT -i lo -j ACCEPT
# Allow all from local network
/sbin/iptables -A INPUT -i "$IF_LAN" -j ACCEPT
# Allow connections out via default gateway
/sbin/iptables -t nat -A POSTROUTING -o "$IF_PUB0" -j MASQUERADE
/sbin/iptables -A FORWARD -i "$IF_PUB0" -o "$IF_LAN" -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i "$IF_LAN" -o "$IF_PUB0" -j ACCEPT
/sbin/iptables -A INPUT -i "$IF_PUB0" -m state --state RELATED,ESTABLISHED -j ACCEPT
