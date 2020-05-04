#!/bin/bash

TPLINE="`xinput | grep TouchPad`"

if [ $? -ne 0 ];
then
    # Touchpad does not exist
    exit 1
fi

if [[ "$TPLINE" =~ id=([[:digit:]]+) ]];
then
    DEVID="${BASH_REMATCH[1]}"
    DEVSTATELINE=`xinput --list-props $DEVID | grep "Device Enabled"`

    if [ $? -ne 0 ];
    then
	# Enablement line did not exist
	exit 1
    fi

    # Must match something like
    # Device Enabled (169):	1
    if [[ "$DEVSTATELINE" =~ .*:.*([[:digit:]]) ]];
    then
	DEVSTATE="${BASH_REMATCH[1]}"
	# Check if enabled.
	if [ "$DEVSTATE" -eq 1 ];
	then
	    # Disabling
	    xinput --disable $DEVID
	    exit $?
	else
	    # If not found, or something strange happened, enable
	    xinput --enable $DEVID
	    exit $?
	fi
    else
	exit 1
    fi
else
    exit 1
fi    

