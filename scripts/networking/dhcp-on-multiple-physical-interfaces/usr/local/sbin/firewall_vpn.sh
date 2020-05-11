#!/bin/sh

. /usr/local/sbin/networking_defs.sh

ADDR_PUB_VPN=`/sbin/ifconfig $IF_PUB0 | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
FIREWALL_TAG_VPN="firewall_vpn"

reset_fw_rules_by_tag "$FIREWALL_TAG_VPN"


# Accept public interface VPN daemon connections to 443
/sbin/iptables -A INPUT -i "$IF_PUB0" -d "$ADDR_PUB_VPN" -m state --state NEW -p tcp --dport 443 -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
# Outbound connection via VPN
/sbin/iptables -A INPUT -i "$IF_TUN" -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i "$IF_TUN" -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i "$IF_PUB0" -o "$IF_TUN" -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i "$IF_TUN" -o "$IF_PUB0" -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
# LAN connections
/sbin/iptables -A FORWARD -i "$IF_TUN" -o "$IF_LAN" -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -t nat -A POSTROUTING -s "$RANGE_OPENVPN" -o "$IF_LAN" -j MASQUERADE -m comment --comment "$FIREWALL_TAG_VPN"
/sbin/iptables -A FORWARD -i "$IF_LAN" -o "$IF_TUN" -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_VPN"

