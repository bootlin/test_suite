#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#
# The base of the test is partly borrowed from LAVA V1 Multinode API's doc

check_status() {
    lava-wait $1
    STATUS=$(grep status /tmp/lava_multi_node_cache.txt | cut -d = -f 2)
    echo "Laptop status is \"$STATUS\""
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

RESULT=0

echo "#### Beginning network board test ####"

echo "Argv1: $1"


lava-wait laptop-ready
LAPTOP=$(grep laptop_ip /tmp/lava_multi_node_cache.txt | cut -d = -f 2)
echo "Using laptop: $LAPTOP"

if ! ping -c 4 $LAPTOP; then
    echo "Can not ping laptop. Aborting."
    lava-send board-ready status=failed
    exit 1
fi
echo "Ping OK."

if ! ping -c 400 -f $LAPTOP; then
    echo "Can not ping flood laptop. Aborting."
    lava-send board-ready status=failed
    exit 1
fi
echo "Ping flood OK"
lava-send board-ready status=ok board_ip=`ip route get 8.8.8.8 | head -n 1 | awk '{print $NF}'`

###### TCP iperf test ######
if ! check_status laptop-tcp-ready; then
    echo "Laptop has a problem. Aborting."
    exit 1
fi
if ! iperf -c $LAPTOP -y c > /tmp/iperf.log; then
    echo "Can not launch iperf or iperf failed. Aborting"
    lava-send board-tcp-done status=failed
    exit 1
fi
BANDWIDTH=$(( $(tail -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000000))
echo "TCP bandwidth: $BANDWIDTH Mbits/sec"
if [ $BANDWIDTH -lt 100 ]; then
    echo "TCP bandwidth too low. Expected: 100 Mbits/sec"
    RESULT=1
else
    echo "TCP bandwidth value OK. (Expected: >100 Mbits/sec)"
fi
lava-send board-tcp-done status=success

###### UDP iperf test ######
if ! check_status laptop-udp-ready; then
    echo "Laptop has a problem. Aborting."
    exit 1
fi
if ! iperf -c $LAPTOP -u -y c > /tmp/iperf.log; then
    echo "Can not launch iperf or iperf failed. Aborting"
    lava-send board-udp-done status=failed
    exit 1
fi
BANDWIDTH=$(( $(tail -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000))
echo "UDP bandwidth: $BANDWIDTH Kbits/sec"
if [ $BANDWIDTH -lt 1000 ]; then
    echo "UDP bandwidth too low. Expected: 1000 Kbits/sec"
    RESULT=1
else
    echo "UDP bandwidth value OK. (Expected: >1000 Kbits/sec)"
fi
lava-send board-udp-done status=success

###### Simultaneous bidirectionnal iperf test ######
iperf -s -y c > /tmp/iperf.log &
echo $! > /tmp/iperf-server.pid
if [ "$(cat /tmp/iperf-server.pid)" = "" ]; then
    echo "Can not launch iperf server. Aborting"
    lava-send board-bi-ready status=failed
    exit 1
fi
lava-send board-bi-ready status=ok

lava-wait laptop-bi-starting
if ! ping -c 1000 -f $LAPTOP; then
    echo "Can not ping flood laptop during iperf test."
    lava-send board-ready status=failed
fi
echo "Ping flood during iperf OK"

if ! check_status laptop-bi-done; then
    echo "Laptop has a problem. Aborting."
    kill_iperf
    exit 1
fi
kill_iperf
cat /tmp/iperf.log
BTL_BANDWIDTH=$(( $(head -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000))
LTB_BANDWIDTH=$(( $(tail -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000))
echo "Board-to-laptop bandwidth: $BTL_BANDWIDTH Kbits/sec"
echo "Laptop-to-board bandwidth: $LTB_BANDWIDTH Kbits/sec"
# if [ $LTB_BANDWIDTH -lt 1000 ]; then
#     echo "Laptop-to-board bandwidth too low. Expected: 1000 Kbits/sec"
#     RESULT=1
# else
#     echo "Laptop-to-board bandwidth value OK. (Expected: >1000 Kbits/sec)"
# fi
# if [ $BTL_BANDWIDTH -lt 1000 ]; then
#     echo "Board-to-laptop bandwidth too low. Expected: 1000 Kbits/sec"
#     RESULT=1
# else
#     echo "Board-to-laptop bandwidth value OK. (Expected: >1000 Kbits/sec)"
# fi

if [ $RESULT -eq 0 ]; then
    echo "####   Successful    ####"
else
    echo "####   There was a non fatal failure somewhere (bandwidth too low?)    ####"
fi
echo "#### End of network board test ####"
exit $RESULT

