# GLXC

## Manage the life of an LXC container through git push/fetch

Here is the philosophy: a GIT repository represents a program or a
content.

A program is meant to be run: for that it needs an given system
environment.

A content is meant to be visualized, manipulated or edited: for that
it needs programs, which need more or less complex environments.

What GLXC (git-lxc) brings is:
* you clone a GIT repository with GLXC-enabled data
* you run: ``` glxc/glxc-client init mycontainer ```
* you push the data to it: ``` git push mycontainer master ```
* read the messages, it shows a URL like http://10.0.3.254/ that you
  may open in your browser to visualize or edit the data

What happens is:
* _glxc-client init_ copies itself into the _.git/_ directory and
  register (itself) as a GIT remote named _mycontainer_ using the
  _ext::_ protocol
* _git push_ pushes the data to _glxc-client_ which:
    * creates the LXC container _mycontainer_ with _lxc-start(1)_
    * start the container
    * initialize the container (through sysconf)
    * run [tree/usr/bin/glxc](/usr/bin/glxc) _git-remote-command_
      inside the container, which does the rest:
        * export some machine state through into GIT commits
        * execute the requested git remote command (_git-receive-pack_
          or _git-upload-pack_)
        * import things from the pushed new GIT commits


Import/export is about:
* MongoDB data:
  [tree/usr/share/glxc/import/mongodb](PUSH) and
  [tree/usr/share/glxc/export/mongodb](PULL) support
* PostgreSQL data:
  [tree/usr/share/glxc/import/mongodb](PUSH) support
* MySQL data
* Application data
* ... anything a handler is defined as a script in
_/usr/share/glxc/import/_ and/or _/usr/share/glxc/export/_.


### push-to-deploy, but also pull-to-backup

After the above commands, you may interact with the container (HTTP
application, databases...), then:
* make a ``` git pull mycontainer master ``` to fetch the new state
  with modifications

Up-to-date data from PostgreSQL, MySQL, etc., is automagically saved
back to GIT files with commits, before being pulled as normal.

The different kinds of exports depend on scripts in
_/usr/share/glxc/export/_. It is quite easy to write new ones
(application data, for example) as GLXC provides like a framework for
it. The magic is about the easiness and interoperability to handle the
whole thing, compared to the complexity.


### Various scenarios

#### The LXC container is like an editor for the GIT repository
#### The GIT repository is a backup for the container


