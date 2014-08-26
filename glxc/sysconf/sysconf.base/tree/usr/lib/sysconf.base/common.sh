# Bash scripts utility functions               -*- shell-script -*-
#
# To be sourced from scripts like this:
#   . /usr/share/sysconf.base/common.sh

# LEGACY
log() {
    nef_log "$@"
}

nef_log() {
    [ "x$NEF_LOG_FILE" = x ] && NEF_LOG_FILE="$LOG_FILE" # Legacy compat

    if [ "x$1" = "x-" ]; then
        while read; do
            nef_log "$REPLY"
        done
        return
    fi

    local txt="$*"
    local line="$*"
    local prefix=$(basename $0)

    if [ "x$NEF_LOG_DATE" = xyes ]; then
        date="`date +'%Y-%m-%d %H:%M:%S:%N' | sed -E 's/.{6}$//'`"
        prefix="$prefix $date"
    fi

    line="$prefix: $line"

    if [ "$NEF_LOG_FILE" = "" ]; then
        echo "$line" >&2
    else
        echo "$line" | tee -a $LOG_FILE >&2
    fi
}

# LEGACY
fatal_error() {
    log "FATAL ERROR: $*"
    exit 1;
}

nef_fatal() {
    log "FATAL ERROR: $*"
    exit 1;
}

nef_usage_error() {
    [ "$1" = "" ] || log "ERROR: $*"
    echo
    show_usage
    exit 1;
}

# Usage: nef_confim "question?" && command...
nef_confirm()
{
    # Inspired from http://stackoverflow.com/questions/1885525/how-do-i-prompt-a-user-for-confirmation-in-bash-script
    read -p "$1 [y/n] ? " -n 1 -r
    echo >&2
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Usage: nef_array_from_lines variable_name "newline-separated list" [IFS]
#   Used in ./README.cheatsheet
nef_array_from_lines()
{
    OLD_IFS="$IFS"
    IFS="$3"
    # [ "q$IFS" = "q" ] &&
 IFS="
"
    local array=( $2 )
    IFS="$OLD_IFS"

    arrayname=$1
    eval "declare -g -a $arrayname=( \"\${array[@]}\" )"
}

# usage: nef_template_apply_file TEMPLATE_PATH
nef_template_apply_file()
{
    template=`cat "$1"`
    templateEscaped=$(echo "$template" | sed 's/"/\\"/g')
    eval "echo \"$templateEscaped\""
}

# usage: nef_hook_run <hook_array_name> [arg1 [arg2 [argN]]]
nef_hook_run()
{
    hookName=$1
    hooks=($(eval echo "\${$hookName[@]}"))
    # $hookName[@]
    # hooks=()
    shift

    for hook in "${hooks[@]}"; do
        $hook "$@"
    done
}

# Search file for occurence of the "-NEF-SHELL-EVAL-" token, and eval what follows
#
# Exemple in:
# /etc/cloud-nef/primary/lxc/http-front-n4-primary-cn.template.conf
nef_shell_eval_file()
{
    token="-NEF-SHELL-EVAL-"
    OLD_IFS="$IFS"
 IFS="
"

    lines=($(cat $1 | grep -- "$token" | sed "s/.*-NEF-SHELL-EVAL-//"))
    IFS="$OLD_IFS"

    for line in "${lines[@]}"; do
        eval $line
    done
}

nef_create_temp_dir()
{
    dir=/tmp/nef.`date +%s.%N`.$$
    mkdir -p $dir
    chmod 700 $dir
    echo $dir
}

nef_format_ip()
{
    format=dotted

    case "$1" in
        --dotted)
            format=dotted
            shift
            ;;
        --decimal)
            format=decimal
            shift
            ;;
    esac

    if echo "$1" | grep -q '\.'; then
        oldIFS=$IFS
        IFS="."
        declare -a ipArray=($1)
        IFS=$oldIFS

        typeset -i ip=$(( ${ipArray[0]} << 24 | ${ipArray[1]} << 16 | ${ipArray[2]} << 8 | ${ipArray[3]} ))
    else
        typeset -i ip=$(( $1 ))
    fi

    case $format in
        dotted)
            ip1=$(( $ip >> 24 ))
            ip2=$(( $ip >> 16 & 255))
            ip3=$(( $ip >> 8 & 255))
            ip4=$(( $ip & 255))

            echo $ip1.$ip2.$ip3.$ip4
            ;;
        decimal)
            echo $ip
            ;;
    esac
    # echo $ip
}

nef_increment_text()
{
    sed 's/^/    /'
}
