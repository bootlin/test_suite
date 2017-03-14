#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#

echo "MMC test"

white_list="
beaglebone-black
sama53d
"
MUST_RUN=0
for i in $white_list; do
    if [ "$i" = "$1" ]; then
        MUST_RUN=1
    fi
done
if [ $MUST_RUN -eq 0 ]; then
    echo "Board not white-listed"
    echo "Not running the test and exiting successfully"
    exit 0
fi
echo "Running test..."
exit 0

DEVICE_NUMBER=$(dmesg |grep "new high speed SDHC card at address"|tail -n 1|cut -d ' ' -f 3|cut -c 4)
DEVICE="/dev/mmcblk$DEVICE_NUMBER"

echo "Testing raw write"
dd if=/dev/urandom bs=1M count=1 |tee >(md5sum) >(dd of=/dev/mmcblk0) >/dev/null
exit 0
# dd if=/dev/random of=$DEVICE bs=1M count=200 conv=fdatasync

echo "Cleaning up the device using raw write"
dd if=/dev/zero of=$DEVICE bs=1M count=14 conv=fdatasync

echo "Partitionning"
sfdisk $DEVICE << EOF
,3M,L
,60,L
,19,S
,42M,E
,130,L
,130,L
,130,L
,,L
EOF

mkfs.ext4 ${DEVICE}p1

PART_LIST=$(ls $DEVICE*)
echo $PART_LIST

mkdir -p /tmp/mountpoint
mount ${DEVICE}p1 /tmp/mountpoint

echo "And the test suite sentence you to troll!" > /tmp/mountpoint/troll
ls -l /tmp/mountpoint|grep troll
cat /tmp/mountpoint/troll

mount|grep $DEVICE

umount /tmp/mountpoint
rm -rf /tmp/mountpoint

