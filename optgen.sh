#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
## Helper script to autogenerate getopts code out of the target script's help message
## The script must contain a usage description with '##' at the beginning of each line (that is, like this one)
##
##      usage: getopt.sh [options]
##
##      options:
##           -s <script_path> The path to the script to be parsed
##           -d               Enable debug logs [default:0]

which xclip > /dev/null
do_xclip=$?

# Default values
_d=0

# No-arguments is not allowed
[ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1

# Parsing flags and arguments
while getopts 'hs:d' OPT; do
    case $OPT in
        h)
            sed -ne 's/^## \(.*\)/\1/p' $0
            exit 1
            ;;
        s)
            _script_path=$OPTARG
            ;;
        d)
            _d=1
            ;;
        \?)
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' $0
            exit 1
            ;;
    esac
done

log_debug(){
    [ $_d -eq 1 ] && echo $@
}

varsfile=$(mktemp /tmp/varsfile.XXX)
sed -n 's_^##\s*-\(.*\)_\1_p' $_script_path | sed -n 's|\(\w\)\s*<\(\w\+\)>|\1: _\2=$OPTARG|p' | cut -d ' ' -f1,2 > $varsfile
sed -n 's_^##\s*-\(.*\)_\1_p' $_script_path | sed -n '/\w\s*<\w\+>/! s|\(\w\)|\1 _\1=1|p' | cut -d ' ' -f1,2 >> $varsfile

flaglist=`cut -d ' ' -f1  $varsfile | tr -d '\n'`
variables=`cut -d ' ' -f2  $varsfile`

defaults=$(mktemp /tmp/defaults.XXX)
sed -n 's_^##\s*-\(.*\)_\1_p' $_script_path | sed -n 's|\(\w\)\s*<\(\w\+\)>\s*.*\[default:\s*\(.*\)\]|_\2=\3|p' > $defaults
sed -n 's_^##\s*-\(.*\)_\1_p' $_script_path | sed -n '/\w\s*<\w\+>/! s|\(\w\)\s*.*\[default:\s*\(.*\)\]|_\1=\2|p' >> $defaults

log_debug content of varsfile
[ $_d -eq 1 ] && cat $varsfile && echo

log_debug content of defaults
[ $_d -eq 1 ] && cat $defaults && echo

exec 5<&1
exec 1> ./tmpfile

variables_n=$(cat $varsfile | wc -l)
defaults_n=$(cat $defaults | wc -l)

if [ ${defaults_n} -gt 0 ]; then
    echo "# Default values"
    cat $defaults
fi

if [ ${defaults_n} -lt ${variables_n} ]; then
cat << EOF

# No-arguments is not allowed
[ \$# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' \$0 && exit 1
EOF

fi

cat << EOF

# Parsing flags and arguments
while getopts 'h${flaglist}' OPT; do
    case \$OPT in
        h)
            sed -ne 's/^## \(.*\)/\1/p' \$0
            exit 1
            ;;
EOF

IFS=$'\n'       # make newlines the only separator
for j in $(cat $varsfile)
do
    flag=$(echo $j | cut -c1)
    var=$(echo $j | cut -d' ' -f2)
    cat << EOF
        $flag)
            $var
            ;;
EOF
done


cat << EOF
        \?)
            echo "---"
            sed -ne 's/^## \(.*\)/\1/p' \$0
            exit 1
            ;;
    esac
done
EOF

# Show result in stdout
cat ./tmpfile >&5
# Copy result in system clipboard
cat ./tmpfile | xclip
cat ./tmpfile | xclip -sel clip
