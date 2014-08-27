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

###
# START doing things in share/textree

_old_pwd=$PWD
cd tree/usr/share/textree

# 'forever' come from NPM and provide NodeJS process management
if ! npm list forever -g >/dev/null; then
    nef_log "Installing NPM modules..."
    npm install forever -g
    npm install --unsafe-perm \
        || nef_fatal "could not install npm modules for textree"
fi
# npm install --unsafe-perm --verbose http://registry.npmjs.org/nodegit/-/nodegit-0.1.4.tgz \
#     || nef_fatal "could not build and install nodegit-0.1.4"
nef_log "Building and installing nodegit (which is really tricky)..."
(
    cd node_modules
    rm -rf nodegit
    export PATH=$PATH:$PWD/nodegit/node_modules/.bin
    mkdir nodegit \
        && curl http://registry.npmjs.org/nodegit/-/nodegit-0.1.4.tgz \
        | tar xz --strip-components=1 -C ./nodegit \
        && cd nodegit \
        && npm --unsafe-perm install ejs \
        && npm --unsafe-perm run codegen \
        && npm --unsafe-perm install \
        && node install
) || nef_log "failed to build and install nodegit"

cd $_old_pwd

# END doing things in share/textree
###

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
