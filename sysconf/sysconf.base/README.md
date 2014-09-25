# Sysconf

Sysconf suggests a way to organise custom system files (like
```/etc``` config or ```/usr/bin/``` scripts) in a central directory
that is easy to manage, backup and sync.

[The idea](doc/logic.md) is to move any custom file like
```/etc/cron.daily/some-task```) to
```/sysconf/actual/tree/etc/cron.daily/some-task``` and replace the
original file with a symbolic link pointing toward its location in
```/sysconf/``` .

## Just a bash script

As a shell script, the [```sysconf tool```](tree/usr/bin/sysconf)
provides commands to manipulate the ```/sysconf``` tree:

* ```sysconf compile``` : build all symbolic links into ```/sysconf/compiled```
* ```sysconf install``` : install ```/sysconf/compiled``` into the target (```/``` by default)
* ```sysconf update``` : run all profiles' ```install.sh``` script
* ```sysconf add``` : move the given file to Sysconf and replace with symbolic link
* ```sysconf list``` : list compiled symlinks

For detailed information, execute ```sysconf --help``` or read the
[script's source code](tree/usr/bin:sysconf) directly.


## Documentation

* [Usage instructions](doc/usage.md)
* [Specification of Sysconf directories](doc/specification.md)
* [Logic behind Sysconf explained](doc/logic.md)
* [Original project requirements](doc/requirements.md)
* [FAQ](doc/faq.md)
  

## Authors & history

This tool was was designed and implemented is maintained so far by
Jean-Francois Gigand <jf@gigand.fr>.

The first version of [the script](tree/usr/bin/sysconf) was written in
early 2014 and released as Free Software on GitHub a few months later.
