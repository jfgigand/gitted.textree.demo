
# README of your project

Quick presentation.
  
## A Gitted-powered install

This software is packaged using
[Gitted](https://github.com/geonef/sysconf.gitted), which use the LXC
containers to make it run, and GIT for updates, backups and data sync.

* [LXC](https://linuxcontainers.org/) pseudo-virtualization technology
  running on Linux ;
  
* [GIT](http://git-scm.com/) is the #1 distributed version control
  system ;

* [GITTED](https://github.com/geonef/gitted) is a shell-based tool
  that let you manage the service's data through ```git pull``` and
  ```git push``` commands.

## Quick start instructions

```
git clone https://github.com/project/repos.git && cd repos
sysconf/gitted-client register && sysconf/gitted-client add vm-repos
git push vm-repos master
```

If it fails because of a network error, remove the VM and retry :
```
lxc-destroy -f -n vm-repos
git push vm-repos master
```

The server is now running. You may run ```lxc-ls -f``` to know its IP
address:
```
NAME           STATE    IPV4        IPV6  AUTOSTART  
---------------------------------------------------
vm-repos       RUNNING  10.0.3.254  -     NO
```

That output indicates the IP of the server. You can access it at: ```http://10.0.3.254/```
