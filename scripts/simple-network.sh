#!/bin/sh

echo "#### Beginning simple network board test ####"

NH=192.168.2.1

if [ $(ip l | wc -l) -le 2 ]; then
    echo "Only the loopback interface is registered"
    exit 1
fi

if ! ping -c 4 $NH; then
    echo "Cannot ping $NH. Aborting."
    exit 1
fi
echo "Ping OK."

echo "#### End of network board test ####"
exit 0
