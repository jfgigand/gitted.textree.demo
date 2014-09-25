# Step-by-step explanation of the logic behind Sysconf

* See also: [Project requirements](requirements.md)

## A way to centralize configuration files

Suppose you have a file, ```/etc/cron.daily/some-task```, that you need
to share or backup across different systems:
```
/etc/cron.daily/some-task
```

The idea is to move the file to a central versionned tree in ```/sysconf``` and
replace ```/etc/cron.daily/some-task``` with a symbolic link pointing
to it:
```
/etc/cron.daily/some-task -> /sysconf/actual/tree/etc/cron.daily/some-task
/sysconf/actual/tree/etc/cron.daily/some-task
```

With this organisation, the ```/sysconf``` directory can be
versionned, backed-up and synced between different systems.

And still, files can be edited in place as usual
(```/etc/cron.daily/some-task``` in this example) while being
tracked easily in ```/sysconf```, because of the symbolic links.

### Separating between profiles

In most cases, it is not enough to make a single separation between
*system*-maintained files (managed by *apt-get*, *yum*, etc.) and
custom *sysconf*-maintained files. Any system serves a purpose that
can be structed in different layers. These layers are called
**profiles**.

#### **Example**: a developer team's desktop system
... can be devided into these layers:
* host-specific: what is unique to this very system, for example
  ```/etc/hosts```; this layer is named: **actual**
* shared with team: what is shared with the colleagues, for example
  a ```/usr/share/git-hook/commit-msg``` script responsible for the
  validation of the team projects' commit messages; this layer is
  named: **team**
* personal settings: what the developer shares with his home computer,
  for example shell aliases in ```/etc/bash.bashrc```; this layer is
  named: **personal**

Profiles lie in their respective directory into ```/sysconf```:
```
/sysconf/actual/tree/etc/hosts
/sysconf/sysconf.team/tree/usr/share/git-hook/commit-msg
/sysconf/sysconf.personal/tree/etc/bash.bashrc
```

The symbolic links become as follows:
```
/etc/hosts                     -> /sysconf/actual/tree/etc/hosts
/usr/share/git-hook/commit-msg -> /sysconf/sysconf.team/tree/usr/share/git-hook/commit-msg
/etc/bash.bashrc               -> /sysconf/sysconf.personal/tree/etc/bash.bashrc
```

### Profile inheritance and file *overloading*

*Overloading* is a an Object-oriented programming concept which in our
case lets a Sysconf profile define a file that is already defined by
another profile.

Suppose you have a profile *A* meant to customize profile *B* with a
more specific version of a given file, say, ```/etc/bash.bashrc```.
We would have the following ```/sysconf``` tree:
```
/sysconf/sysconf.A/tree/etc/bash.bashrc
/sysconf/sysconf.B/tree/etc/bash.bashrc
```

The symbolic link ```/etc/bash.bashrc``` should point to *A*'s, not
*B*'s. To indicate this, a ```deps``` file is created into
```/sysconf/sysconf.A``` which specifies that *A* depends on *B*, that
*A* **extends** *B*: *A*'s tree takes precedence over *B*'s tree.

### The root profile: ```actual```

If profiles can extend each other, dependant profiles must be
processed last. It is necessary to know what is the first profile: by
convention, it is named ```actual```. In Object-oriented programming
it is said to be the **final concrete** class (profile).

Sysconf will start by processing ```/sysconf/actual```, then recurse
into the profiles whose names are listed in
```/sysconf/actual/deps``` and so on.


## Dynamic settings: the ```install.sh``` script

Statically organised files are not enough when you need to
**generate** some files, install packages or more generally, execute
custom commands.

To do that, profiles may define an ```install.sh``` file containing
shell commands which are executed the command ```sysconf update```.

For multiple profiles, the ```install.sh``` scripts of the
dependencies are executed **before** the ```install.sh``` script of
the profile that depend on them.

In other words, if *A* depends on *B*, the order will be: (1)
```/sysconf/sysconf.A/install.sh```, then (2)
```/sysconf/sysconf.B/install.sh``` .


## Splitting ```config``` into ```config.d/*.config```

The ```conf.d``` pattern, widely used on the *Debian GNU/Linux*
distribution among others, is about turning a configuration **file**
(like ```conf```) into a **directory** (like ```conf.d```) where the config lies into
multiple files.

Where the pattern is enabled, it is easy to have sysconf-managed
files, for example: ```/etc/nginx/sites-available/```,
```/etc/logrotate.d/```, etc.

But there are programs distributed with a unique config file:

* some allow include directives with wildcards: it is the case of
```/etc/network/interfaces``` to which we can add: ```source
/etc/network/interfaces.d/*.interfaces```;

* some allow include directives without wildcard: it is the case of
  ```/etc/gitconfig``` where included files need to be listed
  explicitely under the ```[include]``` section;

* some do not allow any includes anyway: it is the case of
  ```/etc/hosts``` which need to be updated in place with the
  concatenation of ```/etc/hosts/*.hosts```.


Once the mecanism is enabled for a particular file (for example,
```/etc/hosts```), every Sysconf profile can take advantage of it by
providing its specific config (```/etc/hosts/profile-a.hosts``` for
example) in a clean and non-obstrusive way.

This is why Sysconf provides
[sysconf-etc.d](../tree/usr/bin/sysconf-etc.d), a generic tool that fix
the required config files, which are by default:

* ```/etc/hosts``` out of ```/etc/hosts/*.hosts```
* ```/etc/ssh/ssh_config``` out of ```/etc/ssh/ssh_config.d/*.ssh_config```
* ```/etc/ssh/sshd_config``` out of ```/etc/ssh/sshd_config.d/*.sshd_config```
* ```/etc/gitconfig``` out of ```/etc/gitconfig.d/*.gitconfig```

Other files can be acted upon, when specified through a
```.meta.conf``` file in ```/etc/sysconf/etc.d```: see
[etc/sysconf/etc.d/README.md](../tree/etc/sysconf/etc.d) for more
information.
