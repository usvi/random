#!/bin/bash
SCANNER=xerox_mfp:libusb:001:002
SCAN_LOCATION_BASE=/media/scans
SCAN_SLEEP_SECS=7

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
	scanimage -d $SCANNER > $FULL_FILEPREFIX.pnm
	sleep $SCAN_SLEEP_SECS
	convert $FULL_FILEPREFIX.pnm $FULL_FILEPREFIX.jpg
	rm $SCAN_LOCATION_BASE/$YEAR/$FILEPREFIX.pnm
	
    fi
	
done
