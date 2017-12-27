#!/bin/sh
#
# Maxime Ripard <maxime@free-electrons.com>
#

echo "#### Starting NAND UBI test ####"

# Define here the partitions given the LAVA device-type
case $1 in
    "sun5i-gr8-chip-pro")
        PARTITIONS="/dev/mtd4"
    ;;
    # You can add more device-type here
esac

for PARTITION in $PARTITIONS; do
    if ! ls $PARTITION; then
        echo "Can't find ${PARTITION}. Aborting"
        echo "Here are the available partitions:"
        ls -l /dev/mtd*
        exit 1
    fi

    echo "Fomatting UBI device on $PARTITION"
    if ! ubiformat $PARTITION; then
        echo "Can't format ${PARTITION}. Aborting"
        exit 1
    fi

    echo "Attaching UBI device on $PARTITION"
    if ! ubiattach -p $PARTITION; then
        echo "Can't attach ${PARTITION}. Aborting"
        exit 1
    fi

    echo "Creating UBI volume"
    if ! ubimkvol /dev/ubi0 -N test $PARTITION; then
        echo "Can't create volume. Aborting"
        exit 1
    fi

    MOUNTPOINT="/tmp/mountpoint"
    echo "Mounting UBI volume to $MOUNTPOINT"
    mkdir -p $MOUNTPOINT
    if ! mount -t ubifs ubi0:test $MOUNTPOINT; then
        echo "Can't mount volume to ${MOUNTPOINT}. Aborting"
        exit 1
    fi

    SMALL_FILE="$MOUNTPOINT/small"
    BIG_FILE="$MOUNTPOINT/big"
    if ! dd if=/dev/urandom of=$SMALL_FILE bs=1 count=128; then
        echo "Can't create our small file. Aborting"
        exit 1
    fi
    SMALL_CHECKSUM=$(sha1sum $SMALL_FILE)

    if ! dd if=/dev/urandom of=$BIG_FILE bs=1M count=200; then
        echo "Can't create our big file. Aborting"
        exit 1
    fi
    BIG_CHECKSUM=$(sha1sum $BIG_FILE)

    echo "Unmounting $PARTITION"
    if ! umount /tmp/mountpoint; then
        echo "Can't unmount ${PARTITION}. Aborting"
        exit 1
    fi

    echo "Reounting UBI volume to $MOUNTPOINT"
    mkdir -p $MOUNTPOINT
    if ! mount -t ubifs ubi0:test $MOUNTPOINT; then
        echo "Can't mount volume to ${MOUNTPOINT}. Aborting"
        exit 1
    fi

    echo "Checking the files"
    if ! ls $SMALL_FILE; then
        echo "Can't find $SMALL_FILE. Aborting"
        exit 1
    fi

    if ! echo "$SMALL_CHECKSUM" | sha1sum -c; then
        echo "Checksum of $SMALL_FILE didn't match. Aborting"
        exit 1
    fi

    if ! ls $BIG_FILE; then
        echo "Can't find $BIG_FILE. Aborting"
        exit 1
    fi

    if ! echo "$BIG_CHECKSUM" | sha1sum -c; then
        echo "Checksum of $BIG_FILE didn't match. Aborting"
        exit 1
    fi
    
    if ! ls $SMALL_FILE $BIG_FILE; then
        echo "Can't find $TEXT_FILE or $BIG_FILE anymore in ${MOUNTPOINT}. Aborting"
        exit 1
    fi

    echo "Cleaning up"
    echo "Unmounting $PARTITION"
    if ! umount $MOUNTPOINT; then
        echo "Can't unmount ${PARTITION}. Aborting"
        exit 1
    fi

    rm -rf $MOUNTPOINT
done

echo "#### NAND UBI test passed    ####"
exit 0

