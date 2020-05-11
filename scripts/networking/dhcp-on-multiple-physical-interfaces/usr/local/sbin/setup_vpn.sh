#!/bin/sh

. /usr/local/sbin/networking_defs.sh

ADDR_PUB_VPN=`/sbin/ifconfig $IF_PUB0 | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
OPENVPN_CONF_LISTEN="/etc/openvpn/listen.conf"

echo "# Include this to openvpn confs via" > "$OPENVPN_CONF_LISTEN"
echo "# config /etc/openvpn/listen.conf" >> "$OPENVPN_CONF_LISTEN"
echo "#" >> "$OPENVPN_CONF_LISTEN"
echo "local $ADDR_PUB_VPN" >> "$OPENVPN_CONF_LISTEN"
service openvpn restart
