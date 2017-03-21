#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#
# The base of the test is partly borrowed from LAVA V1 Multinode API's doc

check_status() {
    lava-wait $1
    STATUS=$(grep status /tmp/lava_multi_node_cache.txt | cut -d = -f 2)
    echo "Board status is \"$STATUS\""
    if [ "$STATUS" = "failed" ]; then
        return 1
    fi
    return 0
}
kill_iperf() {
    echo "Killing iperf"
    if ! kill -9 "$(cat /tmp/iperf-server.pid)"; then
        echo "Can not kill iperf."
        return 1
    fi
    return 0
}

echo "#### Beginning network laptop test ####"

echo "Argv1: $1"

echo "Announcing readiness"
lava-send laptop-ready laptop_ip=`ip route get 8.8.8.8 | head -n 1 | awk '{print $NF}'`
if ! check_status board-ready; then
    echo "Board has a problem. Aborting."
    exit 1
fi
BOARD=$(grep board_ip /tmp/lava_multi_node_cache.txt | cut -d = -f 2)
echo "Using board: $BOARD"

###### TCP iperf test ######
iperf -s &
echo $! > /tmp/iperf-server.pid
if [ "$(cat /tmp/iperf-server.pid)" = "" ]; then
    echo "Can not launch iperf server. Aborting"
    lava-send laptop-tcp-ready status=failed
    exit 1
fi
lava-send laptop-tcp-ready status=ok

if ! check_status board-tcp-done; then
    echo "Board has a problem. Aborting."
    kill_iperf
    exit 1
fi
kill_iperf

###### UDP iperf test ######
iperf -s -u &
echo $! > /tmp/iperf-server.pid
if [ "$(cat /tmp/iperf-server.pid)" = "" ]; then
    echo "Can not launch iperf server. Aborting"
    lava-send laptop-udp-ready status=failed
    exit 1
fi
lava-send laptop-udp-ready status=ok

if ! check_status board-udp-done; then
    echo "Board has a problem. Aborting."
    kill_iperf
    exit 1
fi
kill_iperf

###### Bidirectionnal iperf test ######
if ! check_status board-bi-ready; then
    echo "Board has a problem. Aborting."
    exit 1
fi
lava-send laptop-bi-starting
if ! iperf -c $BOARD -d -t 20; then
    echo "Can not launch iperf or iperf failed. Aborting"
    lava-send laptop-bi-done status=failed
    exit 1
fi
lava-send laptop-bi-done status=success


echo "####   Successful    ####"
echo "#### End of network laptop test ####"
exit 0

