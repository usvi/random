#!/bin/sh

. /usr/local/sbin/networking_defs.sh

ADDR_PUB_VPN=`/sbin/ifconfig $IF_GW | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
FIREWALL_TAG_VPN="firewall_vpn"

reset_fw_rules_by_tag $FIREWALL_TAG_VPN


# Allow VPN
#
# Outbound connection via vpn
#
/sbin/iptables -A INPUT -i $IF_GW -d $ADDR_PUB_VPN -m state --state NEW -p tcp --dport 443 -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A INPUT -i $IF_TUN -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i $IF_TUN -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i $IF_GW -o $IF_TUN -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
#
# LAN connections
#
/sbin/iptables -A FORWARD -i $IF_TUN -o $IF_GW -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -t nat -A POSTROUTING -s $RANGE_OPENVPN -o $IF_LAN -j MASQUERADE -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i $IF_LAN -o $IF_TUN -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i $IF_TUN -o $IF_LAN -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"

