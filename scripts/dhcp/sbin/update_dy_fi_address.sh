#/bin/bash

INTERFACE=$1
HOSTNAME=$2
DYFI_CREDENTIALS=$(head -n 1 /etc/dy.fi_credentials.dat)
DYFI_ADDRESS_DATA_DIR=/var/lib/dyfi
UPDATE=no
TIME_TRESHOLD=432000 #432000 = 5 days

mkdir -p $DYFI_ADDRESS_DATA_DIR

# 1. If old dy.fi address is different than current (and current exists), update with current always
# 2. If adresses are the same, update only if enough time has passed

# Get current ip address (exit if not get
CURRENT_IP=`/sbin/ifconfig $INTERFACE | grep 'inet addr:' | sed s/.*'inet addr:'// | sed s/' '.*//`

if [ -z $CURRENT_IP ]; then
    exit 1;
fi

# Try to get stored ip address
OLD_IP=$(head -n 1 $DYFI_ADDRESS_DATA_DIR/$INTERFACE.dat)

# Make all the checks on the address data
if [ -z $OLD_IP ]; then
    # No old ip on record -> update
    UPDATE=yes
elif [ $CURRENT_IP != $OLD_IP ]; then
    # Different IP addresses -> update
    UPDATE=yes
else
    TIME_DIFF=$((`date +%s` - `stat -c %Y $DYFI_ADDRESS_DATA_DIR/$INTERFACE.dat`))

    if [ $TIME_DIFF -gt $TIME_TRESHOLD ]; then
	# Threshold too much -> update!
	UPDATE=yes
    fi
fi


if [ $UPDATE = "yes" ]; then

    curl --interface $INTERFACE -D - --user $DYFI_CREDENTIALS https://www.dy.fi/nic/update?hostname=$HOSTNAME
    echo $CURRENT_IP > $DYFI_ADDRESS_DATA_DIR/$INTERFACE.dat
fi
