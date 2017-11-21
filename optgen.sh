#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
## Helper script to autogenerate getopts code out of the target script's help message
## The script must contain a usage description with '##' at the beginning of each line (that is, like this one)
##
##      usage: getopt.sh [options]
##
##      options:
##           -s, --script <path> The path to the script to be parsed
##           -d, --debug         Enable debug logs [default:0]

# GENERATED_CODE: start
# Default values
_debug=0

# No-arguments is not allowed
[ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--script") set -- "$@" "-s";;
    "--debug") set -- "$@" "-d";;
    *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hds:' OPT; do
    case $OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' $0
           exit 1 ;;
        d) _debug=1 ;;
        s) _script=$OPTARG ;;
        \?) print_illegal $@ >&2;
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' $0
            exit 1
            ;;
    esac
done
# GENERATED_CODE: end


# PARSE HELP MESSAGE ----------------------------------------------------------------
BOOLS_SHORT_REGEX='/<\w+>|--\w+/! s|^##\s*-(\w)\s*.*|\1 _\1=1|p'
BOOLS_LONG_REGEX='/<\w+>/! s|^##\s*-(\w), --(\w+)\s*.*|\1 _\2=1|p'
VALUES_SHORT_REGEX='/--\w+/! s|^##\s*-(\w).*<(\w+)>|\1: _\2=$OPTARG|p'
VALUES_LONG_REGEX='s|^##\s*-(\w), --(\w+).*<\w+>|\1: _\2=$OPTARG|p'

DEFAULTS_BOOLS_SHORT_REGEX='/<\w+>|--\w+/! s|^##\s*-(\w)\s*.*\[default:\s*(.*)\]|_\1=\2|p'
DEFAULTS_BOOLS_LONG_REGEX='/<\w+>/! s|^##\s*-\w, --(\w+)\s*.*\[default:\s*(.*)\]|_\1=\2|p'
DEFAULTS_VALUES_SHORT_REGEX='/--\w+/! s|^##.*<(\w+)>.*\[default:\s*(.*)\]|_\1=\2|p'
DEFAULTS_VALUES_LONG_REGEX='s|^##\s*-\w, --(\w+)\s*<\w+>.*\[default:\s*(.*)\]|_\1=\2|p'

LONG_TO_SHORT_MAP_REGEX='s_^##\s*(-\w),\s*(--\w+)\s*_"\2") set -- "$@" "\1";; |_p'


variables=$(mktemp /tmp/variables.XXX)
sed -nE "$BOOLS_SHORT_REGEX"  "$_script" | cut -d ' ' -f1,2 > $variables
sed -nE "$BOOLS_LONG_REGEX"   "$_script" | cut -d ' ' -f1,2 >> $variables
sed -nE "$VALUES_SHORT_REGEX" "$_script" | cut -d ' ' -f1,2 >> $variables
sed -nE "$VALUES_LONG_REGEX"  "$_script" | cut -d ' ' -f1,2 >> $variables


defaults=$(mktemp /tmp/defaults.XXX)
sed -nE "$DEFAULTS_BOOLS_SHORT_REGEX"  "$_script" | cut -d ' ' -f1 > $defaults
sed -nE "$DEFAULTS_BOOLS_LONG_REGEX"   "$_script" | cut -d ' ' -f1 >> $defaults
sed -nE "$DEFAULTS_VALUES_SHORT_REGEX" "$_script" | cut -d ' ' -f1 >> $defaults
sed -nE "$DEFAULTS_VALUES_LONG_REGEX"  "$_script" | cut -d ' ' -f1 >> $defaults


long_to_short_map=$(mktemp /tmp/long_to_short_map.XXX)
sed -nE "$LONG_TO_SHORT_MAP_REGEX" "$_script" | cut -d ' ' -f1-5 > $long_to_short_map

[ $_debug = 1 ] && {
    echo ----- variables
    cat $variables
    echo ----- defaults
    cat $defaults
    echo ----- long_to_short_map
    cat $long_to_short_map
}

exec 5<&1
exec 1> ./tmpfile

echo "# GENERATED_CODE: start"

# GENERATE HEADER -------------------------------------------------------------------
variables_n=$(cat $variables | wc -l)
defaults_n=$(cat $defaults | wc -l)

[ ${defaults_n} -gt 0 ] && {
    echo "# Default values"
    cat $defaults
}

# Allow no-arguments only if all variables have default values
[ ${defaults_n} -lt ${variables_n} ] && {
cat << EOF

# No-arguments is not allowed
[ \$# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' \$0 && exit 1
EOF
}


# CONVERT LONG OPTIONS INTO SHORT ---------------------------------------------------

cat <<EOF

# Converting long-options into short ones
for arg in "\$@"; do
  shift
  case "\$arg" in
EOF

IFS=$'|'       # make newline the only separator
for j in $(cat $long_to_short_map); do
echo $j
done
cat << EOF
  *) set -- "\$@" "\$arg"
  esac
done
EOF


# GENERATE FLAG ERROR function ------------------------------------------------------

cat << EOF

function print_illegal() {
    echo Unexpected flag in command line \"\$@\"
}
EOF

# GENERATE OPTGETS CODE -------------------------------------------------------------

flaglist=`cut -d ' ' -f1  $variables | tr -d '\n'`
cat << EOF

# Parsing flags and arguments
while getopts 'h${flaglist}' OPT; do
    case \$OPT in
        h) sed -ne 's/^## \(.*\)/\1/p' \$0
           exit 1 ;;
EOF

IFS=$'\n'       # make newline the only separator
for j in $(cat $variables)
do
    flag=$(echo $j | cut -c1)
    var=$(echo $j | cut -d' ' -f2)
    cat << EOF
        $flag) $var ;;
EOF
done


cat << EOF
        \?) print_illegal \$@ >&2;
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' \$0
            exit 1
            ;;
    esac
done
# GENERATED_CODE: end
EOF

# Show result in stdout
cat ./tmpfile >&5

which xclip > /dev/null
do_xclip=$?

[ $do_xclip ] && {
# Copy result in system clipboard
cat ./tmpfile | xclip
cat ./tmpfile | xclip -sel clip
}
rm ./tmpfile
