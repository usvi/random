#!/bin/sh

. /usr/local/sbin/firewall_defs.sh

ADDR_PUB_ASUKA=`/sbin/ifconfig $IF_ASUKA | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
FIREWALL_TAG_ASUKA="firewall_asuka"

reset_fw_rules_by_tag $FIREWALL_TAG_ASUKA


# Www redirections
/sbin/iptables -t nat -A PREROUTING -i $IF_ASUKA -p tcp -d $ADDR_PUB_ASUKA --dport 80 -j DNAT --to-destination $ADDR_PRIV_ASUKA:80 -m comment --comment "$FIREWALL_TAG_ASUKA"
/sbin/iptables -t nat -A PREROUTING -s $RANGE_LAN -d $ADDR_PUB_ASUKA -j DNAT --to-destination $ADDR_PRIV_ASUKA -m comment --comment "$FIREWALL_TAG_ASUKA"
/sbin/iptables -t nat -A POSTROUTING -s $RANGE_LAN -d $ADDR_PRIV_ASUKA -j SNAT --to-source $ADDR_PRIV_GW -m comment --comment "$FIREWALL_TAG_ASUKA"
/sbin/iptables -A FORWARD -p tcp -d $ADDR_PRIV_ASUKA --dport 80 -j ACCEPT -m comment --comment "$FIREWALL_TAG_ASUKA"
/sbin/iptables -A FORWARD -s $ADDR_PRIV_ASUKA -j ACCEPT -m comment --comment "$FIREWALL_TAG_ASUKA"
/sbin/iptables -t nat -I POSTROUTING -s $ADDR_PRIV_ASUKA -j SNAT --to-source $ADDR_PUB_ASUKA -m comment --comment "$FIREWALL_TAG_ASUKA"
