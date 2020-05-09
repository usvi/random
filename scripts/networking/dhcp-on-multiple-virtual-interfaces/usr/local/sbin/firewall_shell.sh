#!/bin/sh

. /usr/local/sbin/networking_defs.sh

ADDR_PUB_SHELL=`/sbin/ifconfig $IF_SHELL | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
FIREWALL_TAG_SHELL="firewall_shell"
ADDR_PUB_GW=`/sbin/ifconfig $IF_GW | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`

reset_fw_rules_by_tag $FIREWALL_TAG_SHELL


# Allow shell
# Allow receiving messages to for example locally bound interface:
/sbin/iptables -A INPUT -i $IF_SHELL -d $ADDR_PUB_SHELL -m state --state RELATED,ESTABLISHED -j ACCEPT -m comment --comment "$FIREWALL_TAG_SHELL"
/sbin/iptables -t nat -A PREROUTING -i $IF_SHELL -p tcp -d $ADDR_PUB_SHELL --dport 1:65535 -j DNAT --to-destination $ADDR_PRIV_SHELL:22 -m comment --comment "$FIREWALL_TAG_SHELL"
# Needed for VPN and NAT hairpinning:
/sbin/iptables -t nat -A PREROUTING -s $RANGE_LAN -d $ADDR_PUB_SHELL -p tcp --dport 1:65535 -j DNAT --to-destination $ADDR_PRIV_SHELL:22 -m comment --comment "$FIREWALL_TAG_SHELL"
/sbin/iptables -t nat -A POSTROUTING -s $RANGE_LAN -d $ADDR_PRIV_SHELL -p tcp --dport 22 -j SNAT --to-source $ADDR_PUB_GW -m comment --comment "$FIREWALL_TAG_SHELL"
#
/sbin/iptables -A FORWARD -d $ADDR_PRIV_SHELL -j ACCEPT -m comment --comment "$FIREWALL_TAG_SHELL"
/sbin/iptables -A FORWARD -s $ADDR_PRIV_SHELL -j ACCEPT -m comment --comment "$FIREWALL_TAG_SHELL"
# Shell outbound connections
/sbin/iptables -t nat -I POSTROUTING -s $ADDR_PRIV_SHELL -j SNAT --to-source $ADDR_PUB_SHELL -m comment --comment "$FIREWALL_TAG_SHELL"

