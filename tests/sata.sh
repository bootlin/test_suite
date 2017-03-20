#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#

echo "#### Beginning SATA test ####"


DEVICE=""

for i in $(lsblk -lSno NAME);
do
    if dmesg | grep "Attached SCSI disk" | grep $i >/dev/null; then
        DEVICE="/dev/$i"
        break
    fi
done

if [ "$DEVICE" = "" ]; then
    echo "No device found. Aborting"
    exit 1
fi

echo "Using device: $DEVICE"

if ! ls $DEVICE; then
    echo "Can't find ${DEVICE}. Aborting"
    exit 1
fi

echo "Testing raw write"
if ! dd if=/dev/urandom of=$DEVICE bs=1M count=200; then
    echo "Can't perform raw write to $DEVICE. Aborting"
    exit 1
fi

echo "Testing raw read"
if ! dd if=$DEVICE of=/dev/null bs=1M count=200; then
    echo "Can't perform raw read from $DEVICE. Aborting"
    exit 1
fi

echo "Partitionning"
sfdisk $DEVICE << EOF
,300M,L
,60,L
,,L
EOF
if ! [ $? -eq 0 ]; then
    echo "Can't create partitions on $DEVICE. Aborting"
    exit 1
fi

PARTITION="${DEVICE}3"
echo "Creating ext4 filesystem on $PARTITION"
if ! mkfs.ext4 -F -F $PARTITION; then
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

mount|grep $DEVICE

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

echo "Checking performances with Bonnie++"
if ! adduser -S -D -H bonnie; then # System user without password nor home
    echo "Can't create bonnie user. Aborting"
    exit 1
fi

if ! chown -R bonnie $MOUNTPOINT; then
    echo "Can't give folder rights to bonnie. Aborting"
    exit 1
fi

if ! bonnie\+\+ -u bonnie -s 4G -d $MOUNTPOINT; then
    echo "Bonnie++ seems to have failed somewhere. Aborting"
    exit 1
fi

echo "Cleaning up"
echo "Unmounting $PARTITION"
if ! umount $MOUNTPOINT; then
    echo "Can't unmount ${PARTITION}. Aborting"
    exit 1
fi

rm -rf $MOUNTPOINT

echo "####    Successful    ####"
echo "#### End of SATA test ####"
exit 0

