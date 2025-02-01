#!/bin/sh
#SCANNER=xerox_mfp:libusb:001:003
SCANNER=""
SCAN_LOCATION_BASE=/media/scans
SCAN_SLEEP_SECS=7

SCANNER_USB_ID_VENDOR="04e8"
SCANNER_USB_ID_DEVICE="3441"

USB_DEVICES_SYS_BASE="/sys/bus/usb/devices"
USB_SYS_FILE_CONFIGURATION="bConfigurationValue"
USB_SYS_FILE_VENDOR="idVendor"
USB_SYS_FILE_DEVICE="idProduct"

USB_SYS_SETTING_OFF=0
USB_SYS_SETTING_ON=1
USB_SYS_SETTING_WAIT=1


while sleep 1;
do
    /usr/local/bin/samsungpoll | grep -v pressed &>/dev/null
    PRESSED=$?

    if [ $PRESSED -eq 1 ];
    then
	YEAR=`date +'%Y'`
	FILEPREFIX=`date +'%Y-%m-%d___%H-%M-%S'`_scan

	if [ ! -d $SCAN_LOCATION_BASE/$YEAR ];
	then
	    mkdir $SCAN_LOCATION_BASE/$YEAR
	fi
	FULL_FILEPREFIX=$SCAN_LOCATION_BASE/$YEAR/$FILEPREFIX

	# Check first if we have not used scanner and if necessary,
	# sniff it out.
	if [ -z $SCANNER ];
	then
	    SCANNER=`sane-find-scanner -q | grep SCX | sed "s/.* at //;"`
	fi
	
	scanimage -d "xerox_mfp:$SCANNER" > $FULL_FILEPREFIX.pnm

	# If we failed to scan, power off the scanner, then power back
	# on and sniff again.
	
	if [ $? -ne 0 ];
	then

	    USB_SYS_PATH_CONFIGURATION=""

	    for TEMP_USB_SYS_PATH in "$USB_DEVICES_SYS_BASE"/*
	    do
		if [ -f "$TEMP_USB_SYS_PATH/$USB_SYS_FILE_VENDOR" -a \
			-f "$TEMP_USB_SYS_PATH/$USB_SYS_FILE_DEVICE" ]
		then

		    if [ "`cat $TEMP_USB_SYS_PATH/$USB_SYS_FILE_VENDOR`" = "$SCANNER_USB_ID_VENDOR" -a \
			 "`cat $TEMP_USB_SYS_PATH/$USB_SYS_FILE_DEVICE`" = "$SCANNER_USB_ID_DEVICE" ]
		    then
			USB_SYS_PATH_CONFIGURATION="$TEMP_USB_SYS_PATH/$USB_SYS_FILE_CONFIGURATION"
		    fi
		fi
	    done

	    if [ -f "$USB_SYS_PATH_CONFIGURATION" ]
	    then
		echo "$USB_SYS_SETTING_OFF" > "$USB_SYS_PATH_CONFIGURATION"
		sleep "$USB_SYS_SETTING_WAIT"
		echo "$USB_SYS_SETTING_ON" > "$USB_SYS_PATH_CONFIGURATION"
	    fi
	    
	    SCANNER=`sane-find-scanner -q | grep SCX | sed "s/.* at //;"`
	    scanimage -d "xerox_mfp:$SCANNER" > $FULL_FILEPREFIX.pnm
	fi

	sleep $SCAN_SLEEP_SECS
	convert $FULL_FILEPREFIX.pnm $FULL_FILEPREFIX.jpg
	rm $SCAN_LOCATION_BASE/$YEAR/$FILEPREFIX.pnm
	
    fi
	
done
