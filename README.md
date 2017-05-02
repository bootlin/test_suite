# Custom tests

## Adding a new test

Write your program in the `scripts` folder. If the test is valid, it must
return `0`, otherwise, the test is considered as failed.

Then you need to add its corresponding YAML file in the `tests` folder, to allow
LAVA to run it. Don't hesitate to have a look at the existing ones. Still, here
is a simple one:

```
metadata:
    format: Lava-Test Test Definition 1.0
    name: My-test-name

run:
    steps:
        - lava-test-case a-custom-test-name --shell ./scripts/my_test.sh $DEVICE
```

  * `My-test-name` is only metadata, and is not that important
  * `lava-test-case` is the command
  * `a-custom-test-name` is the name that will be given in the TestCase instance
    in LAVA
  * `./scripts/my_test.sh $DEVICE` is the call to the script you want to run,
    passing $DEVICE as argument. It's what makes the test to pass or fail
    depending on the return value.

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
have to think that you have two roles: `laptop` and `board`.

Each role has its own shell script to run, in which you can call some helpers
provided by LAVA to synchronize them.

The YAML file must be adapted a bit to call the right scripts. Here is and
example:
```
metadata:
    format: Lava-Test Test Definition 1.0
    name: my-test-multinode

run:
    steps:
        - ./tests_multinode/my-test-`lava-role`.sh `lava-self`
```

Here is a very simple example of that file, that will just call
`./tests_multinode/my-test-laptop.sh my_laptop` on the laptop, and
`./tests_multinode/my-test-board.sh my_board`.

Here, `lava-role` returns the role the command is running on, and `lava-self` is
the device name.

Don't hesitate to have a look at the `network.yaml`, `network-laptop.sh`, and
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



