#!/bin/sh

. /usr/local/sbin/networking_defs.sh

ADDR_PUB2=`/sbin/ifconfig $IF_PUB2 | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
FIREWALL_TAG_PUB2="firewall_pub_002"
ADDR_PUB_GW=`/sbin/ifconfig $IF_PUB0 | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`

reset_fw_rules_by_tag "$FIREWALL_TAG_PUB2"


# Generics
/sbin/iptables -A INPUT -i "$IF_PUB2" -d "$ADDR_PUB2" -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_PUB2"
/sbin/iptables -t nat -I POSTROUTING -s "$ADDR_PRIV2" -j SNAT --to-source "$ADDR_PUB2" -m comment --comment "$FIREWALL_TAG_PUB2"
/sbin/iptables -A FORWARD -d "$ADDR_PRIV2" -j ACCEPT -m comment --comment "$FIREWALL_TAG_PUB2"
/sbin/iptables -A FORWARD -s "$ADDR_PRIV2" -j ACCEPT -m comment --comment "$FIREWALL_TAG_PUB2"


# I personally use this script (firewall_interface2.sh) to
# redirect port 80 to a local network WWW server 80,
# so here are the specific rules:
/sbin/iptables -t nat -A PREROUTING -i "$IF_PUB2" -p tcp -d "$ADDR_PUB2" --dport 80 -j DNAT --to-destination "$ADDR_PRIV2:80" -m comment --comment "$FIREWALL_TAG_PUB2"
/sbin/iptables -t nat -A PREROUTING -s "$RANGE_LAN" -d "$ADDR_PUB2" -p tcp --dport 80 -j DNAT --to-destination "$ADDR_PRIV2" -m comment --comment "$FIREWALL_TAG_PUB2"
/sbin/iptables -t nat -A POSTROUTING -s "$RANGE_LAN" -d "$ADDR_PRIV2" -p tcp --dport 80 -j SNAT --to-source "$ADDR_PUB_GW" -m comment --comment "$FIREWALL_TAG_PUB2"
