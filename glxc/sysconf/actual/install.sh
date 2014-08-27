# sysconf install script for sysconf profile for this custom system

. /usr/lib/sysconf.base/common.sh

# Install NodeJS and fix bon/node -> nodejs
sysconf_require_packages nodejs \
    || nef_fatal "could not install nodejs"
[ -x /usr/bin/node ] || ln -s nodejs /usr/bin/node

# Install NPM
if [ ! -x /usr/bin/npm ]; then
    curl https://www.npmjs.org/install.sh | sh \
        || nef_fatal "could not install npm"
fi

# 'forever' come from NPM and provide NodeJS process management
npm install -g forever \
    || nef_fatal "could not install npm module: forever"

# Manage the textree service

update-rc.d textree defaults

if service textree status >/dev/null; then
    service textree restart \
        || nef_fatal "could not restart textree"
else
    service textree start \
        || nef_fatal "could not start textree"
fi
