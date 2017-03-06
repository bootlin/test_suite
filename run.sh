#!/bin/sh
#
# Skia < skia AT libskia DOT so >
#
# Beerware licensed software - 2017
#

cd $(dirname $0)

for i in ./tests/*.sh; do
    echo "--> Running $i";
    if ./$i;
    then
        echo "--> Test $i PASSED";
    else
        echo "--> Test $i FAILED";
    fi
done


