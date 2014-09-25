
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

gitted_new_commit=$(git show-ref -s refs/heads/$GITTED_GIT_BRANCH)
