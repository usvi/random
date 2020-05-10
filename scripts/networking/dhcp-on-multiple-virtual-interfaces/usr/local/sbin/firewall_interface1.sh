#!/bin/sh

. /usr/local/sbin/networking_defs.sh

ADDR_PUB1=`/sbin/ifconfig $IF_PUB1 | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
FIREWALL_TAG_PUB1="firewall_pub_001"
ADDR_PUB_GW=`/sbin/ifconfig $IF_PUB0 | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`

reset_fw_rules_by_tag $FIREWALL_TAG_PUB1


# Allow shell
# Allow receiving messages to for example locally bound interface:
/sbin/iptables -A INPUT -i $IF_PUB1 -d $ADDR_PUB1 -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_PUB1"
/sbin/iptables -t nat -A PREROUTING -i $IF_PUB1 -p tcp -d $ADDR_PUB1 --dport 1:65535 -j DNAT --to-destination $ADDR_PRIV1:22 -m comment --comment "$FIREWALL_TAG_PUB1"
# Needed for VPN and NAT hairpinning:
/sbin/iptables -t nat -A PREROUTING -s $RANGE_LAN -d $ADDR_PUB1 -p tcp --dport 1:65535 -j DNAT --to-destination $ADDR_PRIV1:22 -m comment --comment "$FIREWALL_TAG_PUB1"
/sbin/iptables -t nat -A POSTROUTING -s $RANGE_LAN -d $ADDR_PRIV1 -p tcp --dport 22 -j SNAT --to-source $ADDR_PUB_GW -m comment --comment "$FIREWALL_TAG_PUB1"
#
/sbin/iptables -A FORWARD -d $ADDR_PRIV1 -j ACCEPT -m comment --comment "$FIREWALL_TAG_PUB1"
/sbin/iptables -A FORWARD -s $ADDR_PRIV1 -j ACCEPT -m comment --comment "$FIREWALL_TAG_PUB1"
# Shell outbound connections
/sbin/iptables -t nat -I POSTROUTING -s $ADDR_PRIV1 -j SNAT --to-source $ADDR_PUB1 -m comment --comment "$FIREWALL_TAG_PUB1"

