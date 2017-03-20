# Custom tests

## Adding a new test

Just add your program in the `tests` folder. If the test is valid, it must
return `0`, otherwise, the test is considered as failed.

Be careful that the test must be able to run on the target, with a very simple
rootfs. Most of the common tools are unavailable.

Also, the only available shell is Busybox's Ash. Don't try to run some Bash or
you'll get some strange errors that are not always explicit.

Don't hesitate to read the other tests to see how they are implemented.
