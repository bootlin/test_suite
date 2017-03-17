#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#

echo "#### Beginning MMC test ####"

# Define here the partitions given the LAVA device-type
case $1 in
    "sama53d")
        PARTITIONS="
/dev/mmcblk0p1
"
    ;;
    # You can add more device-type here
esac

for PARTITION in $PARTITIONS; do
    if ! ls $PARTITION; then
        echo "Can't find ${PARTITION}. Aborting"
        exit 1
    fi

    echo "Creating ext4 filesystem on $PARTITION"
    if ! yes | mkfs.ext4 $PARTITION; then
        echo "Can't make filesystem on ${PARTITION}. Aborting"
        exit 1
    fi

    MOUNTPOINT="/tmp/mountpoint"
    echo "Mounting $PARTITION to $MOUNTPOINT"
    mkdir -p $MOUNTPOINT
    if ! mount $PARTITION $MOUNTPOINT; then
        echo "Can't mount $PARTITION to ${MOUNTPOINT}. Aborting"
        exit 1
    fi

    TEXT_FILE="$MOUNTPOINT/text_file"
    BIG_FILE="$MOUNTPOINT/big_file"
    SENTENCE="And the test suite sentence you to troll!"
    echo "Creating some files on $PARTITION"
    if ! echo "$SENTENCE" > $TEXT_FILE; then
        echo "Can't create ${TEXT_FILE}. Aborting"
        exit 1
    fi

    if ! dd if=/dev/urandom of=$BIG_FILE bs=1M count=200; then
        echo "Can't create ${BIG_FILE}. Aborting"
        exit 1
    fi

    CHECKSUM=$(sha1sum $BIG_FILE)
    echo $CHECKSUM

    echo "Unmounting $PARTITION"
    if ! umount /tmp/mountpoint; then
        echo "Can't unmount ${PARTITION}. Aborting"
        exit 1
    fi

    echo "Remounting $PARTITION to $MOUNTPOINT"
    if ! mount $PARTITION $MOUNTPOINT; then
        echo "Can't remount $PARTITION to ${MOUNTPOINT}. Aborting"
        exit 1
    fi

    echo "Checking the files"
    if ! ls $TEXT_FILE $BIG_FILE; then
        echo "Can't find $TEXT_FILE or $BIG_FILE anymore in ${MOUNTPOINT}. Aborting"
        exit 1
    fi

    if ! grep "$SENTENCE" $TEXT_FILE; then
        echo "Can't find my sentence anymore in ${TEXT_FILE}. Aborting"
        exit 1
    fi


    if ! echo "$CHECKSUM"|sha1sum -c; then
        echo "SHA1 sum of $BIG_FILE failed. Aborting"
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

echo "####   Successful    ####"
echo "#### End of MMC test ####"
exit 0

