# Custom tests

## Adding a new test

Write your program in the `scripts` folder. If the test is valid, it must
return `0`, otherwise, the test is considered as failed.

Be careful that the test must be able to run on the target, with a very simple
rootfs. Most of the common tools are unavailable.

Also, the only available shell is Busybox's Ash. Don't try to run some Bash or
you'll get some strange errors that are not always explicit.

Don't hesitate to read the other tests to see how they are implemented.

When run, the test will be passed the device-type it's running on as first
argument. Thus you can make some parts of the test board-specific if needed.  
**Be careful:** the device-type is the one used by LAVA, and therefore may not
correspond to the DT name, or any other name.

## Adding a multinode test (with two boards)

When you add a multinode test, one of the two boards is an x86 laptop which will
serve as reference, and which is automatically added to the job. Thus you just
have to think that you have two roles: `laptop` and `board`, making you need to
write two scripts: `$TESTNAME-laptop.sh` and `$TESTNAME-board.sh`.

The two scripts can call some helpers provided by LAVA to synchronize themself.

Don't hesitate to have a look at the `network-laptop.sh`, and
`network-board.sh` files to get a more concrete overview of how to write a
multinode test.

### Helpers

`lava-role` and `lava-self` are not the only helpers provided by LAVA in a
Multinode test. `lava-wait` and `lava-send` are also available, and really
useful among all the others `lava-*` commands.

All those helpers can be used in the shell scripts called in Multinode tests.

A complete reference can be found here:
https://staging.validation.linaro.org/static/docs/v2/multinodeapi.html

If needed, some helpers are also available in single tests, but still are less
usefull than the multinode ones. Here is the reference:
https://staging.validation.linaro.org/static/docs/v2/lava_test_shell.html#writing-a-test-for-lava-test-shell



