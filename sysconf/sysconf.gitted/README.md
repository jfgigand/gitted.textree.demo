# Gitted: Import/export machine sate through git push/pull

Gitted solves 2 problems:

* website software *installation* (for example, a CMS like Drupal) can
  be complex to install and configure, because of the dependencies
  that are needed on the system ;

* website *state* (for example, MySQL data) is difficult to manage:
  doing simple database dumps are often not enough, if it needs file
  uploads, applicative plugins, etc.

To address these issues, Gitted helps you manage the website
software *and* the changing data as one unique thing, which is stored
as a GIT repository.


## Documentation

* [Understanding Gitted](doc/understanding.md)
* [How to use a Gitted-powered GIT repository](doc/howto-manipulate.md)
* [How to setup Gitted for an application](doc/howto-create-new.md)


## Authors & history

This tool was was designed and implemented is maintained so far by
Jean-Francois Gigand <jf@gigand.fr>.

The first version of [the script](tree/usr/bin/sysconf) was written in
early 2014 and released as Free Software on GitHub a few months later.
