Useful links:
[Homepage README](../README.md);
[How to setup Gitted for an application](howto-create-new.md).

# How to manipulate a Gitted-powered repository

A [Gitted](https://github.com/geonef/sysconf.gitted)-powered Git
repository enables you to easily:

* build the LXC container to run the service: for example, a MediaWiki
  repository will build a fully configured MediaWiki server app.
  
* fetch data updates of the service using ```git fetch```

* edit application data as flat files: for example, MediaWiki pages
  are stored as flat text files that you can edit with any text editor

* using ```git push```, update the service with the modification you
  have made on the flat files and commited locally or pulled from
  another clone

* make multiple instances of the service with ```gitted-client add```
  for redundancy, load-balancing, backing-up or offline use

This page explains how to use Gitted for these use cases and explains
the logic from that perspective.



## Get the service running

A *Gitted-powered repository* is a normal Git repository (hosted on
GitHub or not) that has a ```sysconf/``` directory and provides the
```sysconf/gitted-client``` script along with
[Sysconf](https://github.com/geonef/sysconf.base) profiles lying into
```sysconf/``` .

As a user, you don't need to dive into *Sysconf*. Just remember that
```sysconf/``` is responsible for setting-up the LXC container
that is going to be created/updated when you run ```git push```.

But first, you need to **enable** Gitted on this repository by
running:
```
sysconf/gitted-client register
```

This will copy the *gitted-client* to the *.git/* directory and
save a reference to the *sysconf/* tree.

Then, register the *gitted-client* special remote:
```
sysconf/gitted-client add container-name
```

You may list the remote that has been created by doing a ```git remote
-v```.

The repository is now set up. You may now create and destroy the
service container the way you like.

Get the service running, in a *push-to-deploy* fashion:
```
git push container-name master
```

### Destroy the service container and build a new one

You can destroy the container using
```
lxc-destroy -n container-name -f
```

Then push again, it will be re-created like on first time:
```
git push container-name master
```

### Multiple containers for the same repository

You can register as many remotes with ```gitted-client add```:
```
sysconf/gitted-client add container1
sysconf/gitted-client add container2
sysconf/gitted-client add container3
```

And build them like we did before:
```
git push container1 master
git push container2 master
git push container3 master
```

Doing that will create 3 identical containers. Thay are the same
because they are build out of the same Git tree (the *master*
branch).

### Pushing specific branches to specific containers

Instead of *master*, you can push any branch to any container. If you
have a *dev* branch, for example, you can do:
```
git push container2 dev:master
```

We write ```dev:master``` because the branch is still named
```master``` on the container. Doing ```git push container2 dev```
would create a ```dev``` branch on the container. It is fine, but it
won't interact with the container state.


## Pulling updates from service containers

It is no different than pulling updates from a remote repository:
```
git fetch container-name
```

During that operation, the service container exports into files
whatever state data it needs to, creating the relevant Git commits
(inside the container) that are finally fetched by your command.

From the container perspective, it is an **export** operation. To
learn how it is done, read:
[How to setup Gitted for an application](doc/howto-create-new.md).

As usual, the ```git fetch container-name``` command alone will not
merge anything into your local branch, it only update the
*container-name* remote branches, likely ```container-name/master```.

Now, since the state data is fetched, it is like having a backup. You
may even destroy the container (```lxc-destroy -n container-name
-f```) without loosing anything.

To finally merge the updates into the local branch, do as usual:
```
git merge container-name/master
```

As Git provides, you can use ```git pull``` to fetch and merge in one
go:
```
git pull container-name master
```

### Exporting container state into a new local branch

To export the container's *master* state into a new local branch named *latest-changes*:
```
git fetch container-name
git branch latest-changes container-name/master
```


## Synchronise the state data of 2 containers

Continuing from above, if you have created the branch
```latest-changes``` with the state data of the container
```container-name```, you can easily update ```container2``` with
theses changes:
```
git push container2 latest-changes:master
```

It can fail with a *Non-fastforwarding changes rejected* error if the
state of *container2* has changed in the meantime, being the same than
when you try to push work to an upstream repository but someone else
has pushed other work before you.

If so, just merge it as usual:
```
git checkout latest-changes
git pull container2 master
```

Resolve any conflict if it happens, then push again:
```
git push container2 latest-changes:master
```

Done! You have successfully updated *container2* with the changes made
in *container-name*.
