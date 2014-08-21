# Installer script for sysconf "nef.service.aire"  -*- shell-script -*-

. /usr/lib/sysconf.base/common.sh


# Fix /etc/host with our hostname
# (and avoid Apache's "apr_sockaddr_info_get() failed" error)
hostname=$(hostname)
ip=$(ip -o -4 addr show dev eth0 primary  | sed -r 's/.* inet ([0-9.]+).*/\1/')
grep -q "^$hostname " /etc/hosts \
    || echo "$ip $hostname" >>/etc/hosts

# because the sources.list installed by lxc download template doesn't work well
echo "Fixing packages..."
echo "deb http://ftp.fr.debian.org/debian/ wheezy main contrib" >/etc/apt/sources.list
apt-get update

sysconf_apt-get install --yes --no-upgrade git curl

# Setup the GIT repository, heart of glxc
in_private_repos=/local.repository.git
if [ ! -d $in_private_repos ]; then
    echo "Initializing repository: $in_private_repos"
    _opts=""

    # /origin.repository.git may have been shared by the host.
    # If so, we use it as a base repository to avoid a full copy, see git-init(1)
    [ -d /origin.repository.git ] && _opts="$_opts --reference /origin.repository.git"

    git init --bare $_opts $in_private_repos
fi
