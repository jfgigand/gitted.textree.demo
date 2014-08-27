# sysconf install script for sysconf profile for this custom system

. /usr/lib/sysconf.base/common.sh

sysconf_require_packages nodejs \
    || nef_fatal "could not install nodejs"

echo WHAT
pwd >&2
echo -----
env >&2

# sh install.npm.js \
#     || nef_fatal "could not install npm"

# npm install -g forever \
#     || nef_fatal "could not install npm module: forever"

# update-rc.d glxc-http-server defaults

# service glxc-http start \
#     || nef_fatal "could not start glxc-http"
