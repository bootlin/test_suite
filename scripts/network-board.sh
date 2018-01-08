#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#
# The base of the test is partly borrowed from LAVA V1 Multinode API's doc



case $1 in
    "armada-370-db")
        EXPECTED_TCP_BANDWIDTH=900 # Unidirectionnal test
        EXPECTED_UDP_BANDWIDTH=700 # Unidirectionnal test
        ;;
    "armada-370-rd")
        EXPECTED_TCP_BANDWIDTH=900
        EXPECTED_UDP_BANDWIDTH=700
        ;;
    "armada-388-clearfog")
        EXPECTED_TCP_BANDWIDTH=900
        EXPECTED_UDP_BANDWIDTH=750
        ;;
    "armada-388-gp")
        EXPECTED_TCP_BANDWIDTH=900
        EXPECTED_UDP_BANDWIDTH=750
        ;;
    "armada-xp-linksys-mamba")
        EXPECTED_TCP_BANDWIDTH=900
        EXPECTED_UDP_BANDWIDTH=750
        ;;
    "at91sam9m10g45ek")
        EXPECTED_TCP_BANDWIDTH=85
        EXPECTED_UDP_BANDWIDTH=85
        ;;
    "at91sam9x25ek")
        EXPECTED_TCP_BANDWIDTH=85
        EXPECTED_UDP_BANDWIDTH=75
        ;;
    "at91sam9x35ek")
        EXPECTED_TCP_BANDWIDTH=85
        EXPECTED_UDP_BANDWIDTH=70
        ;;
    "at91rm9200ek")
        EXPECTED_TCP_BANDWIDTH=25
        EXPECTED_UDP_BANDWIDTH=25
        ;;
    "at91-sama5d4_xplained")
        EXPECTED_TCP_BANDWIDTH=90
        EXPECTED_UDP_BANDWIDTH=90
        ;;
    "sama53d")
        EXPECTED_TCP_BANDWIDTH=90
        EXPECTED_UDP_BANDWIDTH=120
        ;;
    *) # All values are in Mbits/sec (80 Mbits/sec should work on most boards)
        EXPECTED_TCP_BANDWIDTH=80 # Unidirectionnal test
        EXPECTED_UDP_BANDWIDTH=80 # Unidirectionnal test
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
    cat /tmp/iperf.log
    echo "Can not launch iperf or iperf failed. Aborting"
    lava-send board-tcp-done status=failed
    exit 1
fi
cat /tmp/iperf.log
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
    cat /tmp/iperf.log
    echo "Can not launch iperf or iperf failed. Aborting"
    lava-send board-udp-done status=failed
    exit 1
fi
cat /tmp/iperf.log
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

if [ $RESULT -eq 0 ]; then
    echo "####   Successful    ####"
    lava-send board-exit status=ok
else
    echo "####   There was a non fatal failure somewhere (bandwidth too low?)    ####"
    lava-send board-exit status=failed
fi
echo "#### End of network board test ####"
exit $RESULT

