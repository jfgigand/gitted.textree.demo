# How to setup Gitted for an application

This page explains how to turn a web application into a Gitted-enabled
GIT repository.

* Parent: [README.md](../README.md)


## Initialize a GIT repository with the minimal Gitted sysconf

```
git init my-app
cd my-app
```

Before going further, you need to make the *master* branch exist by
creating a commit:
```
touch README.md
git add README.md
git commit -m "initial commit"
```

Then import the
[sysconf.gitted profile](https://github.com/geonef/sysconf.gitted) and
its dependency [sysconf.base](https://github.com/geonef/sysconf.base):

```
git subtree add -P sysconf/sysconf.gitted git@github.com:geonef/sysconf.gitted.git master
git subtree add -P sysconf/sysconf.base git@github.com:geonef/sysconf.base.git master
mkdir sysconf/actual
echo sysconf.gitted >sysconf/actual/deps
```

Make the symlink to ease the usage of gitted:
```
ln -s sysconf.gitted/tree/usr/bin/gitted-client sysconf/gitted-client
```

Commit the whole:
```
git add sysconf/actual sysconf/gitted-client
git commit -m "gathered sysconf profiles"
Done!


## Try the minimal system

```
sysconf/gitted-client register
sysconf/gitted-client add test-vm
git push test-vm master
```

The construction of the LXC container happens during the ```git
push``` operation.

You may check that the system is fine and running by listing:
```
lxc-ls -f
```

You may want to start an interactive shell:
```
lxc-attach -n vm-atlas-base /bin/bash
```

Everything is okay? Then destroy the container for now:
```
lxc-destroy -f -n vm-atlas-base
```

## Setup your custom system in sysconf/actual

* Put into ```sysconf/actual/tree``` any file that you need on
  the system. For example,
  ```sysconf/actual/tree/etc/custom.conf``` will be installed
  as ```/etc/custom.conf``` on the system.
  
* Put into ```sysconf/actual/install.sh``` any shell commands
  that need to run to setup the system, for example ```apt-get
  install``` commands, or generating config files

## Update your README with how to run it

* See the [Example README](example-of-readme.md) and update your own
  with the instructions on how to run the service.
