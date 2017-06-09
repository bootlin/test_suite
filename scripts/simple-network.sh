#!/bin/sh

echo "#### Beginning simple network board test ####"

if [ $(ip l | wc -l) -le 2 ]; then
    echo "Only the loopback interface is registered"
    exit 1
fi

GW=$(ip r s | grep default | awk '{print $3}')
if [ "$GW" = "" ]; then
    echo "No default route."
    exit 1
fi

if ! ping -c 4 $GW; then
    echo "Cannot ping $GW. Aborting."
    exit 1
fi
echo "Ping OK."

echo "#### End of network board test ####"
exit 0
