# sysconf install script for sysconf profile for this custom system

. /usr/lib/sysconf.base/common.sh

sysconf_require_packages nodejs \
    || nef_fatal "could not install nodejs"

ln -s nodejs /usr/bin/node

sh install.npm.sh \
    || nef_fatal "could not install npm"

# sed -i 's/env node$/env nodejs/' /usr/bin/npm

npm install -g forever \
    || nef_fatal "could not install npm module: forever"

update-rc.d glxc-http defaults

if service glxc-http status >/dev/null; then
    service glxc-http restart \
        || nef_fatal "could not restart glxc-http"
else
    service glxc-http start \
        || nef_fatal "could not start glxc-http"
fi
