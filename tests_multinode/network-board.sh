#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#
# The base of the test is partly borrowed from LAVA V1 Multinode API's doc



case $1 in
    "armada-370-db")
        EXPECTED_TCP_BANDWIDTH=900 # Unidirectionnal test
        EXPECTED_UDP_BANDWIDTH=700 # Unidirectionnal test
        EXPECTED_BTL_BANDWIDTH=500 # Board-to-laptop for bidirectionnal test
        EXPECTED_LTB_BANDWIDTH=800 # Laptop-to-board for bidirectionnal test
        ;;
    "armada-388-gp")
        EXPECTED_TCP_BANDWIDTH=900
        EXPECTED_UDP_BANDWIDTH=750
        EXPECTED_BTL_BANDWIDTH=850
        EXPECTED_LTB_BANDWIDTH=70
        ;;
    "armada-xp-linksys-mamba")
        EXPECTED_TCP_BANDWIDTH=900
        EXPECTED_UDP_BANDWIDTH=750
        EXPECTED_BTL_BANDWIDTH=900
        EXPECTED_LTB_BANDWIDTH=900
        ;;
    "at91sam9m10g45ek")
        EXPECTED_TCP_BANDWIDTH=85
        EXPECTED_UDP_BANDWIDTH=85
        EXPECTED_BTL_BANDWIDTH=50
        EXPECTED_LTB_BANDWIDTH=50
        ;;
    "at91sam9x25ek")
        EXPECTED_TCP_BANDWIDTH=85
        EXPECTED_UDP_BANDWIDTH=75
        EXPECTED_BTL_BANDWIDTH=50
        EXPECTED_LTB_BANDWIDTH=30
        ;;
    "at91sam9x35ek")
        EXPECTED_TCP_BANDWIDTH=85
        EXPECTED_UDP_BANDWIDTH=70
        EXPECTED_BTL_BANDWIDTH=45
        EXPECTED_LTB_BANDWIDTH=30
        ;;
    "at91-sama5d4_xplained")
        EXPECTED_TCP_BANDWIDTH=90
        EXPECTED_UDP_BANDWIDTH=90
        EXPECTED_BTL_BANDWIDTH=80
        EXPECTED_LTB_BANDWIDTH=80
        ;;
    *) # All values are in Mbits/sec (80 Mbits/sec should work on most boards)
        EXPECTED_TCP_BANDWIDTH=80 # Unidirectionnal test
        EXPECTED_UDP_BANDWIDTH=80 # Unidirectionnal test
        EXPECTED_BTL_BANDWIDTH=80 # Board-to-laptop for bidirectionnal test
        EXPECTED_LTB_BANDWIDTH=80 # Laptop-to-board for bidirectionnal test
        ;;
esac


# You don't need to touch anything below this
# =============================================================


echo "#### Beginning network board test ####"

echo "Argv1: $1"

RESULT=0

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
if [ $BANDWIDTH -lt $EXPECTED_TCP_BANDWIDTH ]; then
    echo "TCP bandwidth too low. Expected: $EXPECTED_TCP_BANDWIDTH Mbits/sec"
    RESULT=1
else
    echo "TCP bandwidth value OK. (Expected: >$EXPECTED_TCP_BANDWIDTH Mbits/sec)"
fi
lava-send board-tcp-done status=success

###### UDP iperf test ######
if ! check_status laptop-udp-ready; then
    echo "Laptop has a problem. Aborting."
    exit 1
fi
# Testing with very high bandwidth (4000 Gbits/sec) to get maximum value
if ! iperf -c $LAPTOP -u -b 4000000000 -y c > /tmp/iperf.log; then
    echo "Can not launch iperf or iperf failed. Aborting"
    lava-send board-udp-done status=failed
    exit 1
fi
BANDWIDTH=$(( $(tail -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000000))
echo "UDP bandwidth: $BANDWIDTH Mbits/sec"
if [ $BANDWIDTH -lt $EXPECTED_UDP_BANDWIDTH ]; then
    echo "UDP bandwidth too low. Expected: $EXPECTED_UDP_BANDWIDTH Mbits/sec"
    RESULT=1
else
    echo "UDP bandwidth value OK. (Expected: >$EXPECTED_UDP_BANDWIDTH Mbits/sec)"
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
BTL_BANDWIDTH=$(( $(head -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000000))
LTB_BANDWIDTH=$(( $(tail -n 1 /tmp/iperf.log | cut -d , -f 9) / 1000000))
echo "Board-to-laptop bandwidth: $BTL_BANDWIDTH Mbits/sec"
echo "Laptop-to-board bandwidth: $LTB_BANDWIDTH Mbits/sec"
if [ $LTB_BANDWIDTH -lt $EXPECTED_LTB_BANDWIDTH ]; then
    echo "Laptop-to-board bandwidth too low. Expected: $EXPECTED_LTB_BANDWIDTH Mbits/sec"
    RESULT=1
else
    echo "Laptop-to-board bandwidth value OK. (Expected: >$EXPECTED_LTB_BANDWIDTH Mbits/sec)"
fi
if [ $BTL_BANDWIDTH -lt $EXPECTED_BTL_BANDWIDTH ]; then
    echo "Board-to-laptop bandwidth too low. Expected: $EXPECTED_BTL_BANDWIDTH Mbits/sec"
    RESULT=1
else
    echo "Board-to-laptop bandwidth value OK. (Expected: >$EXPECTED_BTL_BANDWIDTH Mbits/sec)"
fi

if [ $RESULT -eq 0 ]; then
    echo "####   Successful    ####"
else
    echo "####   There was a non fatal failure somewhere (bandwidth too low?)    ####"
fi
echo "#### End of network board test ####"
exit $RESULT

