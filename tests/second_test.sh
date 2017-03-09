#!/bin/sh
#
# Skia < skia AT libskia DOT so >
#
# Beerware licensed software - 2017
#

echo "Bonjour"

if [ $(tr -cd 0-9 </dev/urandom | head -c 1) -lt 7 ]; then
    echo "true";
    true
else
    echo "false";
    false
fi




