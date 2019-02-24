#!/bin/bash
#SCANNER=xerox_mfp:libusb:001:003
SCANNER=""
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

	# Check first if we have not used scanner and if necessary,
	# sniff it out.
	if [ -z $SCANNER ];
	then
	    SCANNER=`sane-find-scanner -q | grep SCX | sed "s/.* at //;"`
	fi
	
	scanimage -d "xerox_mfp:$SCANNER" > $FULL_FILEPREFIX.pnm

	# If we failed to scan, sniff the scanner again.
	if [ $? -ne 0 ];
	then
	    SCANNER=`sane-find-scanner -q | grep SCX | sed "s/.* at //;"`
	    scanimage -d "xerox_mfp:$SCANNER" > $FULL_FILEPREFIX.pnm
	fi

	sleep $SCAN_SLEEP_SECS
	convert $FULL_FILEPREFIX.pnm $FULL_FILEPREFIX.jpg
	rm $SCAN_LOCATION_BASE/$YEAR/$FILEPREFIX.pnm
	
    fi
	
done
