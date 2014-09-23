
. /usr/share/nef-common/shell-command || exit 2

PATH=/sbin:/usr/sbin:$PATH

_git()
{
    nef_log GIT "$@"
    git "$@" || nef_fatal "fatal: git failed"
}

gitted_state_ref_name()
{
    name=$(echo "$1" | sed 's/[^a-zA-Z0-9._-]//g')
    echo refs/gitted-state/$GITTED_GIT_BRANCH/$name
}

gitted_last_commit=$(git show-ref -s refs/heads/$GITTED_GIT_BRANCH)

export GIT_WORK_TREE=/tmp/git-transform-work-tree
export GIT_INDEX_FILE=/tmp/git-transform-index
rm -f $GIT_INDEX_FILE
[ -d $GIT_WORK_TREE ] && rm -rf $GIT_WORK_TREE
mkdir -p $GIT_WORK_TREE
