#!/bin/sh
#
# Mylène Josserand <mylene@free-electrons.com>
#

echo "#### Starting NAND test ####"

ITERATIONS=10

#Define here the partitions given the LAVA device-type
case $1 in
    "armada-385-ap")
        MTD_NAME="Root"
	;;
    "armada-370-db")
	MTD_NAME="Filesystem"
	;;
    # You can add more device-type here
esac

# Count the number of MTD partitions
NUM_MTD=`ls -l /sys/class/mtd/mtd*/name | wc -l`
NUM_MTD=`expr $NUM_MTD - 1`

# Retrieve the partition according to MTD_NAME
for i in $(seq 0 $NUM_MTD);
do
    if [ `cat /sys/class/mtd/mtd$i/name` = "$MTD_NAME" ]; then
	PARTITION=/dev/mtd$i
	MTD_ID=$i
	echo "Partition $MTD_NAME found in $PARTITION"
	break
    fi
done

if ! ls $PARTITION; then
    echo "Can't find ${PARTITION}. Aborting"
    echo "Here are the available partitions:"
    ls -l /dev/mtd*
    exit 1
fi

# Check which driver we are running to know which tests perform.
# The old pxa3xx driver does not handle bitflip correctly so
# nandbiterrs script will not be executed, for example.
# New driver: "marvell-nfc" - old driver: "pxa3xx"
# The new driver still displays "pxa3x" in the dmesg so we base on
# sysfs to retrieve the current driver used.
echo "Checking which NAND driver we are using"
if ls -l /sys/class/mtd/mtd$MTD_ID/device/driver | grep nfc; then
    echo "Using the new marvell-nfc driver"
    PXA_DRIVER=0
elif ls -l /sys/class/mtd/mtd$MTD_ID/device/driver | grep pxa3; then
    echo "Using the old pxa3xx driver"
    PXA_DRIVER=1
else
    echo "NAND driver not recognized. Aborting"
    exit 1
fi

# Execute nandbiterrs only in case of new "marvell-nfc" driver
if [ $PXA_DRIVER -eq 0 ]; then
    echo "Executing nandbiterrs on $PARTITION"
    if ! nandbiterrs -i $PARTITION; then
	echo "nandbiterrs on ${PARTITION} failed. Aborting"
	exit 1
    fi
fi

echo "Executing nandpagetest on $PARTITION"
if ! nandpagetest -c $ITERATIONS $PARTITION; then
    echo "nandpagetest on ${PARTITION} failed. Aborting"
    exit 1
fi

echo "Executing nandsubpagetest on $PARTITION"
if ! nandsubpagetest -c $ITERATIONS $PARTITION; then
    echo "nandsubpagetest on ${PARTITION} failed. Aborting"
    exit 1
fi

echo "Executing flash_speed on $PARTITION"
if ! flash_speed -d -c $ITERATIONS $PARTITION; then
    echo "flash_speed on ${PARTITION} failed. Aborting"
    exit 1
fi

echo "#### NAND test passed    ####"
exit 0
