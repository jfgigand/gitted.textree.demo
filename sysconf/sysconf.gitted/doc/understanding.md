# Understanding Gitted

## push-to-deploy: Machine and state out of GIT data

What Gitted brings is:
* you clone a GIT repository with Gitted-enabled data
* you run: ``` sysconf/gitted-client init mycontainer ```
* you push the data to it: ``` git push mycontainer master ```
* read the messages, it shows a URL like http://10.0.3.254/ that you
  may open in your browser to visualize or edit the data

What happens is:
* _gitted-client init_ copies itself into the _.git/_ directory, then
  registers itself as a GIT remote named _mycontainer_ using the
  [_ext::_ protocol](http://git-scm.com/docs/git-remote-ext);
* _git push_ pushes the data to _gitted-client_ which:
    * creates the LXC container _mycontainer_ with
      [lxc-create(1)](http://lxc.sourceforge.net/man/lxc-create.html)
    * start the container with
      [lxc-start(1)](http://lxc.sourceforge.net/man/lxc-start.html)
    * initialize the container (through sysconf)
    * run [/usr/bin/gitted](tree/usr/bin/gitted) _git-remote-command_
      inside the container, which does the rest:
        * export some machine state through into GIT commits
        * execute the requested git remote command (_git-receive-pack_
          or _git-upload-pack_)
        * import things from the pushed new GIT commits


Import/export is about:
* MongoDB data:
  [PUSH](tree/usr/share/gitted/import/mongodb) and
  [PULL](tree/usr/share/gitted/export/mongodb) support
* PostgreSQL data:
  [PUSH](tree/usr/share/gitted/import/postgresql) support
* MySQL data:
  [PUSH](tree/usr/share/gitted/import/mysql) and
  [PULL](tree/usr/share/gitted/export/mysql) support
 * ... any XX thing support provided by the scripts
   ```/usr/share/gitted/import/XX``` and
   ```/usr/share/gitted/export/XX```, for example:
     * application data
     * log files...


### pull-to-backup: Machine and state exported as GIT state

After the above commands, you may interact with the container (HTTP
application, databases...), then:
* make a ``` git pull mycontainer master ``` to fetch the new state
  with modifications

Up-to-date data from PostgreSQL, MySQL, etc., is _automagically_ saved
back to GIT files with commits, before being pulled by Git.

The different kinds of exports depend on scripts in
_/usr/share/gitted/export/_. It is quite easy to write new ones
(application data, for example) as Gitted provides a framework for
it. The magic is about the easiness and interoperability to handle the
whole thing, once all particular in/out exchange have been coded
separately.
