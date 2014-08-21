
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

glxc_last_commit=$(git show-ref -s refs/heads/$GLXC_GIT_BRANCH)

export GIT_WORK_TREE=/tmp/git-transform-work-tree
export GIT_INDEX_FILE=/tmp/git-transform-index
rm -f $GIT_INDEX_FILE
[ -d $GIT_WORK_TREE ] && rm -rf $GIT_WORK_TREE
mkdir -p $GIT_WORK_TREE
