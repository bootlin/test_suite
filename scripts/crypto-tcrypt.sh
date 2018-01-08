#!/bin/sh
#
# Florent Jacquet <florent.jacquet@free-electrons.com>
#

# Define here the needed modules given the LAVA device-type
case $1 in
    "armada-370-db"|"armada-370-rd"|"armada-375-db"|"armada-385-db-ap"|"armada-388-clearfog"|"armada-388-gp"|"armada-xp-db"|"armada-xp-gp"|"armada-xp-linksys-mamba"|"armada-xp-openblocks-ax3-4")
        MODULES="
kernel/crypto/tcrypt.ko mode=402 sec=1 # md5 speed
kernel/crypto/tcrypt.ko mode=403 sec=1 # sha1 speed
kernel/crypto/tcrypt.ko mode=404 sec=1 # sha256 speed
kernel/crypto/tcrypt.ko mode=500 sec=1 # AES
"
    ;;
    # You can add more device-type here
esac

# You don't need to touch anything below this
# =============================================================

echo "#### Beginning tcrypt test ####"

cd /lib/modules/$(uname -r)
IFS='
'
for MODULE in $MODULES; do
    echo "==== Probing $MODULE ===="
    eval insmod $MODULE  # Need the eval because of module arguments
done

echo "####     Successful     ####"
echo "#### End of tcrypt test ####"

exit 0
