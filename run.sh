#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#

cd $(dirname $0)

RESULTS=0

for i in ./tests/*.sh; do
    echo "--> Running $i";
    if ./$i;
    then
        echo "--> Test $i PASSED";
    else
        RESULTS=$((RESULTS + 1))
        echo "--> Test $i FAILED";
    fi
done

exit $RESULTS



