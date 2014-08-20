
. /usr/share/nef-common/shell-command || exit 2

PATH=/sbin:/usr/sbin:$PATH

_git()
{
    nef_log GIT "$@"
    git "$@" || nef_fatal "fatal: git failed"
}

glxc_state_ref_name()
{
    name=$1
    echo refs/lxc-state/$GLXC_GIT_BRANCH/$name
}

glxc_new_commit=$(git show-ref -s refs/heads/$GLXC_GIT_BRANCH)
