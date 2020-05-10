#!/bin/sh

IF_GW=eth0
IF_SHELL=eth1
IF_ASUKA=eth2
IF_LAN=eth3

IF_GW_DY_NAME=gw.asuka.dy.fi
IF_SHELL_DY_NAME=shell.asuka.dy.fi
IF_ASUKA_DY_NAME=asuka.dy.fi

ROUTE_INFO_PATH=/var/lib/routes
SCRIPTS_LOCKDIR=$ROUTE_INFO_PATH/lock
NEW_ROUTERS_TIME_TRESHOLD=30

IF_TUN=tun0
RANGE_OPENVPN=172.16.8.0/28
RANGE_LAN=172.16.8.0/24
#ADDR_PUB_GW=83.150.124.235
ADDR_PRIV_GW=172.16.8.254
#ADDR_PUB_SHELL=83.150.124.11
ADDR_PRIV_SHELL=172.16.8.162
#ADDR_PUB_WWW=83.150.124.234
#ADDR_PRIV_WWW=172.16.8.161
ADDR_PRIV_ASUKA=172.16.8.161


LOCK_WAIT_MAX_SECS=15


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
