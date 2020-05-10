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

#Flush chains
/sbin/iptables -F
/sbin/iptables -X
/sbin/iptables -t nat -F
/sbin/iptables -t nat -X

#Drop everything by default
#/sbin/iptables -P INPUT DROP
#/sbin/iptables -P FORWARD DROP
# Temporarily allowing as part of debugging
/sbin/iptables -P INPUT ACCEPT
/sbin/iptables -P FORWARD ACCEPT

#Allow outputs
/sbin/iptables -P OUTPUT ACCEPT
#Allow all on localhost
/sbin/iptables -A INPUT -i lo -j ACCEPT
#Allow all from local network
/sbin/iptables -A INPUT -i $IF_LAN -j ACCEPT


/sbin/iptables -t nat -A POSTROUTING -o $IF_PUB0 -j MASQUERADE
/sbin/iptables -A FORWARD -i $IF_PUB0 -o $IF_LAN -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i $IF_LAN -o $IF_PUB0 -j ACCEPT
/sbin/iptables -A INPUT -i $IF_PUB0 -m state --state RELATED,ESTABLISHED -j ACCEPT

