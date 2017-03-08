#!/bin/bash
INTERFACE=$1

ROUTE_INFO_PATH=/var/lib/routes

if [ -z $INTERFACE ];
then
    echo "No interface given!"
    exit 1
fi


GATEWAY=$(head -n 1 $ROUTE_INFO_PATH/$INTERFACE.dat)
if [ -z $GATEWAY ];
then
    echo "Could not get gateway address!"
    exit 1
fi

# Figure out interface ip
IPADDR=`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`
if [ -z $IPADDR ]; then
    echo "Could not get IP address of interface!"
    exit 1;
fi


# Figure out netmask
NETMASK=`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | sed s/.*'Mask:'// | sed s/' '.*//`
if [ -z $NETMASK ]; then
    echo "Could not get netmask of interface!"
    exit 1;
fi

# Figure out network
IFS=. read -r i1 i2 i3 i4 <<< "$IPADDR"
IFS=. read -r m1 m2 m3 m4 <<< "$NETMASK"
NETWORK=`printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"`
if [ -z $NETWORK ]; then
    echo "Could not calculate network address!"
    exit 1;
fi


# Flush old values
ip route flush table $INTERFACE

while ip rule show | grep "lookup $INTERFACE" &>/dev/null; do
    ip rule del table $INTERFACE
done

# Set new policy routing
ip route add $NETWORK/$NETMASK dev $INTERFACE src $IPADDR table $INTERFACE
ip route add default via $GATEWAY dev $INTERFACE table $INTERFACE
ip rule add from $IPADDR/32 table $INTERFACE
ip rule add to $IPADDR/32 table $INTERFACE
