#!/bin/sh

# Names for interfaces
# Virtual interface for macvlan magic
IF_VIRTUAL_BASE=eth0
# IF_PUB0 is explicit GW in scripts
IF_PUB0=virtual0
IF_PUB1=virtual1
IF_PUB2=virtual2
IF_LAN=eth3
# For Openvpn
IF_TUN=tun0

# LAN-side corresponding addresses and ranges
ADDR_PRIV0=172.16.8.254
ADDR_PRIV1=172.16.8.162
ADDR_PRIV2=172.16.8.161
RANGE_LAN=172.16.8.0/24
RANGE_OPENVPN=172.16.8.0/28

# Dy.fi names
IF_PUB0_DY_NAME=gw.asuka.dy.fi
IF_PUB1_DY_NAME=shell.asuka.dy.fi
IF_PUB2_DY_NAME=asuka.dy.fi

# Other settings
ROUTE_INFO_PATH=/var/lib/routes
SCRIPTS_LOCKDIR=$ROUTE_INFO_PATH/lock
NEW_ROUTERS_TIME_TRESHOLD=30
LOCK_WAIT_MAX_SECS=15

# USE flags: Define non-zero if want enabled
USE_DY_FI="yes"
USE_OPENVPN="yes"

try_lock ()
{
    LOCK_INTERFACE=$1
    LOCK_TRY_TIME=0

    #logger "Interface $LOCK_INTERFACE trying to get a lock"
    
    while [ $LOCK_TRY_TIME -lt $LOCK_WAIT_MAX_SECS ];
    do
	if mkdir $SCRIPTS_LOCKDIR;
	then
	    # Lock acquired
	    break;
	else
	    # Lock not acquired, wait and try again
	    sleep 1;
	    LOCK_TRY_TIME=$(( LOCK_TRY_TIME+1 ));
	fi
    done

    if [ $LOCK_TRY_TIME -ge $LOCK_WAIT_MAX_SECS ];
    then
	logger "Interface $LOCK_INTERFACE could not get a lock! Exiting.";
	sync;
	exit 1;
    fi
    #logger "Interface $LOCK_INTERFACE got a lock"
}


drop_lock ()
{
    LOCK_INTERFACE=$1

    #logger "Interface $LOCK_INTERFACE releasing locking";
    #sync;
    rmdir $SCRIPTS_LOCKDIR;
}


if_has_ip ()
{
    INTERFACE=$1
    TEST_IP=`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`

    if [ -z $TEST_IP ];
    then
	echo "0"
    else
	echo "1"
    fi
}


reset_fw_rules_by_tag ()
{
    if [ -z $1 ];
    then
	return 1;
    fi
    iptables -L INPUT --line-numbers -n | tac | grep $1 | while read line; do iptables -D INPUT `echo $line | sed s/\ .*//`; done
    iptables -L FORWARD --line-numbers -n | tac | grep $1 | while read line; do iptables -D FORWARD `echo $line | sed s/\ .*//`; done
    iptables -L OUTPUT --line-numbers -n | tac | grep $1 | while read line; do iptables -D OUTPUT `echo $line | sed s/\ .*//`; done
    iptables -t nat -L PREROUTING --line-numbers -n | tac | grep $1 | while read line; do iptables -t nat -D PREROUTING `echo $line | sed s/\ .*//`; done
    iptables -t nat -L INPUT --line-numbers -n | tac | grep $1 | while read line; do iptables -t nat -D INPUT `echo $line | sed s/\ .*//`; done
    iptables -t nat -L OUTPUT --line-numbers -n | tac | grep $1 | while read line; do iptables -t nat -D OUTPUT `echo $line | sed s/\ .*//`; done
    iptables -t nat -L POSTROUTING --line-numbers -n | tac | grep $1 | while read line; do iptables -t nat -D POSTROUTING `echo $line | sed s/\ .*//`; done

    return 0;
}
