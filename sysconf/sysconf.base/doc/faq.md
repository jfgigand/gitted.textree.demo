# Frequently Asked Questions about [Sysconf](https://github.com/geonef/sysconf.base)

* [Go back to project README](../README.md)

## Is Git mandatory? Can I use SubVersion, Bazaar or nothing at all?

You are free. Sysconf is not tight with any version management system.

The [logic of Sysconf](logic.md) defines how the ```/sysconf```
directory is organised, not how it should be versionned or synced.

At the moment (2014-09), Sysconf provides a few commands: ```init```,
```fetch```, ```setup``` and ```pull```; which are helpers for
managing Git. These legacy commands will disappear in the future.

The commands ```compile```, ```install```, ```upate```, ```add```,
```cmd``` and ```list``` only work with the logic and do not use Git
at all.

## Can ```/sysconf``` be located somewhere else?

Yes. A different path can be specified through the environment
variable ```SYSCONF_PATH```.

You can specify it at call time:
```
SYSCONF_PATH=/custom/sysconf/path sysconf <cmd> ...
```

Or make it permanent by adding ```export
SYSCONF_PATH=/custom/sysconf/path``` into your ```/etc/bash.bashrc```
or ```~/.bashrc```.


## Can Sysconf symlinks be installed somewhere else than the root tree ```/```?

Yes.

Edit ```/sysconf/target``` (or ```$SYSCONF_PATH/target``` if Sysconf is
located somewhere else) and change its content from ```/``` to the
directory you want the symlinks be installed into.

When you are done, run ```sysconf install``` to install the symlinks on
the new location. You should probably clean any old symlinks: see *How
to uninstall sysconf* below.


## Can Sysconf be used by unpriviledged users?

Yes.

Of course if you can't write to ```/```, you need to customize
```SYSCONF_PATH``` and ```$SYSCONF_PATH/target``` like explained
above.

Using Sysconf at the user level is a common use case, to manage user
config files like ```~/.bashrc```, ```~/.ssh/config```,
```~/.gitconfig```, etc.

For that use, set ```SYSCONF_PATH``` to ```/home/toto/sysconf``` (for
example) and put a single line ```/home/toto``` into the file:
```/home/toto/sysconf/target```. Append the profiles you need and run
```/home/toto/sysconf/sysconf.base/tree/usr/bin/sysconf compile
install update``` to get everything installed.


## How to uninstall sysconf?

* First, remove all links which have been installed by sysconf:
```
    # find /usr/bin/ /etc/ -type l -lname '/sysconf/*' | xargs rm
```
* Then, remove sysconf itself and it's repositories:
```
    # rm -rf /sysconf
```
