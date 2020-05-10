#!/bin/sh

# This script is run from rc.local (and only once)

. /usr/local/sbin/networking_defs.sh

rm -rf $SCRIPTS_LOCKDIR

# No other need to specificly handle interfaces,
# /etc/network/interfaces works somewhat in this.
