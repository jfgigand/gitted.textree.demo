# sysconf install script for sysconf profile for this custom system

. /usr/lib/sysconf.base/common.sh

# Install NodeJS and fix bon/node -> nodejs
# python and build-essential are required to build the nodegit module
sysconf_require_packages nodejs python build-essential
[ -x /usr/bin/node ] || ln -s nodejs /usr/bin/node

# Install NPM
if [ ! -x /usr/bin/npm ]; then
    nef_log "Installing NPM..."
    curl https://www.npmjs.org/install.sh | sh \
        || nef_fatal "could not install npm"
fi

# 'forever' come from NPM and provide NodeJS process management
if ! npm list forever -g >/dev/null; then
    nef_log "Installing NPM modules..."
    npm install forever -g
    cd tree/usr/share/textree
    pwd
    npm install --unsafe-perm \
        || nef_fatal "could not install npm modules for textree"
    npm install --unsafe-perm http://registry.npmjs.org/nodegit/-/nodegit-0.1.4.tgz \
        || nef_fatal "could not build and install nodegit-0.1.4"
    cd -
fi

# Manage the textree service
if [ 0 -eq $(find /etc/rc*.d -name '*[0-9]textree' | wc -l) ]; then
    update-rc.d textree defaults
fi

if service textree status >/dev/null; then
    service textree restart \
        || nef_fatal "could not restart textree"
else
    service textree start \
        || nef_fatal "could not start textree"
fi
