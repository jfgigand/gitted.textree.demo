# Installer script for sysconf "sysconf.gitted"  -*- shell-script -*-

. /usr/lib/sysconf.base/common.sh

# Fix /etc/host with our hostname
# (and avoid Apache's "apr_sockaddr_info_get() failed" error)
hostname=$(hostname)
ip=$(ip -o -4 addr show dev eth0 primary  | sed -r 's/.* inet ([0-9.]+).*/\1/')
grep -q "^$hostname " /etc/hosts \
    || echo "$ip $hostname" >>/etc/hosts

# because the sources.list installed by lxc download template doesn't work well
_old_content="$(cat /etc/apt/sources.list)"
if grep -vq "deb http://ftp.debian.org/debian/" /etc/apt/sources.list; then
    echo "Fixing packages..."
    echo "deb http://ftp.debian.org/debian/ wheezy main contrib" >/etc/apt/sources.list
fi

apt-cache show git >/dev/null 2>&1 \
    || apt-get update \
    || nef_fatal "apt-get failed with status $?"


sysconf_require_packages git curl sudo

# Bring our own git-subtree if git is too old to provide it
[ -x /usr/lib/git-core/git-subtree ] \
    || ln -s git-subtree-from-sysconf /usr/lib/git-core/git-subtree

# Setup the GIT repository, heart of gitted
in_private_repos=/local.repository.git
if [ ! -d $in_private_repos ]; then
    echo "Initializing repository: $in_private_repos"
    _opts=""

    # /origin.repository.git may have been shared by the host.
    # If so, we use it as a base repository to avoid a full copy, see git-init(1)
    [ -d /origin.repository.git ] && _opts="$_opts --reference /origin.repository.git"

    git init --bare $_opts $in_private_repos
fi
