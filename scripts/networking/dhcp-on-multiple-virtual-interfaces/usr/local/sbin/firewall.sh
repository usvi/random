#!/bin/sh

# This script is run from rc.local (and only once)

. /usr/local/sbin/networking_defs.sh

rmdir $SCRIPTS_LOCKDIR

# Create the virtual interfaces
ifconfig $IF_VIRTUAL_BASE up promisc
ip link add link $IF_VIRTUAL_BASE address 00:90:0b:ff:10:5b $IF_GW type macvlan
ip link set $IF_GW up
ip link add link $IF_VIRTUAL_BASE address 00:90:0b:ff:11:5b $IF_SHELL type macvlan
ip link set $IF_SHELL up
ip link add link $IF_VIRTUAL_BASE address 00:90:0b:ff:12:5b $IF_ASUKA type macvlan
ip link set $IF_ASUKA up

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


/sbin/iptables -t nat -A POSTROUTING -o $IF_GW -j MASQUERADE
/sbin/iptables -A FORWARD -i $IF_GW -o $IF_LAN -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i $IF_LAN -o $IF_GW -j ACCEPT
/sbin/iptables -A INPUT -i $IF_GW -m state --state RELATED,ESTABLISHED -j ACCEPT

