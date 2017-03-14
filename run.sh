#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#
# $1 will be set as the current device type the tests are running on

cd $(dirname $0)

RESULTS=0

for i in ./tests/*.sh; do
    echo "--> Running $i $1";
    if ./$i $1;
    then
        echo "--> Test $i PASSED";
    else
        RESULTS=$((RESULTS + 1))
        echo "--> Test $i FAILED";
    fi
done

exit $RESULTS



