#!/bin/sh

IF_GW=eth0
IF_SHELL=eth1
IF_ASUKA=eth2
IF_LAN=eth3

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
