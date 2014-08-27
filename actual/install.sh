# sysconf install script for sysconf profile for this custom system

. /usr/lib/sysconf.base/common.sh

# Debian wheezy does not have git-subtree
if [ ! -f /usr/lib/git-core/subtree ]; then
    cp resource/git-subtree /usr/lib/git-core/subtree \
        && chmod +x /usr/lib/git-core/subtree \
        || nef_fatal "could not install git-subtree"
fi

# Install NodeJS and fix bon/node -> nodejs
sysconf_require_packages nodejs \
    || nef_fatal "could not install nodejs"
ln -s nodejs /usr/bin/node

# Install NPM
if [ ! -f /usr/bin/npm]; then
    curl https://www.npmjs.org/install.sh | sh \
        || nef_fatal "could not install npm"
fi

# 'forever' come from NPM and provide NodeJS process management
npm install -g forever \
    || nef_fatal "could not install npm module: forever"

# Manage the glxc-http service

update-rc.d glxc-http defaults

if service glxc-http status >/dev/null; then
    service glxc-http restart \
        || nef_fatal "could not restart glxc-http"
else
    service glxc-http start \
        || nef_fatal "could not start glxc-http"
fi
