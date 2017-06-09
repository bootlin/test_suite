#!/bin/sh

echo "#### Beginning simple network board test ####"

iface="eth0"
case $1 in
    "armada-7040-db")
        iface="eth1"
	;;
esac

if [ $(ip l | wc -l) -le 2 ]; then
    echo "Only the loopback interface is registered"
    exit 1
fi

if ! dhclient $iface; then
    echo "Cannot obtain a lease. Aborting."
    exit 1
fi

nh=192.168.2.1
if ! ping -c 4 $nh; then
    echo "Cannot ping $nh. Aborting."
    exit 1
fi
echo "Ping OK."

echo "#### End of network board test ####"
exit 0
