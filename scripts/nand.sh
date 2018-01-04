#!/bin/sh
#
# Mylène Josserand <mylene@free-electrons.com>
#

echo "#### Starting NAND test ####"

ITERATIONS=10
TMP_LOG=/tmp/nand.log

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

# Check if the NAND driver exists
if [ -d /sys/bus/platform/drivers/marvell-nfc/ ] ||
       [ -d /sys/bus/platform/drivers/pxa3xx-nand/ ]; then
    echo "NAND driver found, continue"
else
    echo "NAND driver not found, exit with success."
    echo "Check the kernel configuration"
    lava-test-case nand --result skip
    exit 0
fi

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
    cat /sys/class/mtd/mtd*/name
    lava-test-case nand --result fail
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
    lava-test-case nand --result fail
    exit 1
fi

# Execute nandbiterrs only in case of new "marvell-nfc" driver
if [ $PXA_DRIVER -eq 0 ]; then
    echo "Executing nandbiterrs on $PARTITION"
    if ! nandbiterrs -i $PARTITION 2>&1 | tee $TMP_LOG; then
	echo "nandbiterrs on ${PARTITION} failed. Aborting"
	lava-test-case nandbiterrs --result fail
	exit 1
    else
	BITERR_DONE=`grep "Read error after" $TMP_LOG | awk {'print $4'}`
	# nandbiterrs must test the number of ecc + 1
	BITERR_DONE=`expr $BITERR_DONE - 1`
	BITERR_READ=`cat /sys/class/mtd/mtd$MTD_ID/ecc_strength`
	echo "Comparing $BITERR_DONE and $BITERR_READ for nandbiterrs test"
	if [ $BITERR_DONE -ne $BITERR_READ ]; then
	    echo "nandbiterrs results are incorrect. Aborting"
	    lava-test-case nandbiterrs --result fail
	    exit 1
	else
	    echo "nanbiterrs results are correct."
	    lava-test-case nandbiterrs --result pass
	fi
    fi
else
    echo "By-passing nandbiterrs on $PARTITION because of pxa3 driver used"
    lava-test-case nandbiterrs --result skip
fi

echo "Executing nandpagetest on $PARTITION"
if ! nandpagetest -c $ITERATIONS $PARTITION; then
    echo "nandpagetest on ${PARTITION} failed. Aborting"
    lava-test-case nandpagetest --result fail
    exit 1
fi
lava-test-case nandpagetest --result pass

echo "Executing nandsubpagetest on $PARTITION"
if ! nandsubpagetest -c $ITERATIONS $PARTITION; then
    echo "nandsubpagetest on ${PARTITION} failed. Aborting"
    lava-test-case nandsubpagetest --result fail
    exit 1
fi
lava-test-case nandsubpagetest --result pass

echo "Executing flash_speed on $PARTITION"
if ! flash_speed -d -c $ITERATIONS $PARTITION; then
    echo "flash_speed on ${PARTITION} failed. Aborting"
    lava-test-case flash_speed --result fail
    exit 1
fi
lava-test-case flash_speed --result pass

echo "#### NAND test passed    ####"
exit 0
