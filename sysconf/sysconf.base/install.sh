# sysconf install script for conf: "base"



######################################################################
#
# Set up /etc/bash.bashrc to source all /etc/bash.bashrc.d/*.sh

bashrcfile=/etc/bash.bashrc
bashrcdir=/etc/bash.bashrc.d

grep -q $bashrcdir $bashrcfile || cat >>$bashrcfile <<EOF

# Include *.sh files from $bashrcdir
# (added by $0 on $(date))
if [ -d $bashrcdir ]; then
  for i in $bashrcdir/*.sh; do
    if [ -r $i ]; then
      . \$i
    fi
  done
  unset i
fi
EOF

######################################################################
#
# Set up /etc/network/interfaces to source all /etc/network/interfaces.d/*.interfaces
#
# TODO: update sysconf-etc.d to manage that
#
[ -d /etc/network/interfaces.d ] && {
    cat /etc/network/interfaces | grep -q "source /etc/network/interfaces.d" || {
        echo "Fixing /etc/network/interfaces for sourcing interfaces.d/"
        echo >>/etc/network/interfaces
        echo 'source /etc/network/interfaces.d/*.interfaces' >>/etc/network/interfaces
    }
}

sysconf-etc.d update
