#!/bin/sh
#
# Mylène Josserand <mylene@free-electrons.com>
#

# Create short functions to handle pass/fail/skip
lava_pass()
{
    lava-test-case $TEST --result pass
}

lava_fail()
{
    lava-test-case $TEST --result fail
}

lava_skip()
{
    lava-test-case $TEST --result skip
}
