/etc/hosts.d/ - directory that let /etc/hosts content be spread into multiple files

All files in the directory that end with ".hosts"
will be concatenated into /etc/hosts by the 'nef-update-hosts' command.


This is part of the "sysconf.base" package that help sysadmins package
and share system configurations around simple "sysconf profiles"
that depend on each other.
