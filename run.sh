#!/bin/sh
#
# Skia < skia AT libskia DOT so >
#
# Beerware licensed software - 2017
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



