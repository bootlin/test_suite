#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#

echo "Bonjour"

if [ $(tr -cd 0-9 </dev/urandom | head -c 1) -lt 7 ]; then
    echo "true";
    true
else
    echo "false";
    false
fi




