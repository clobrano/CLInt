# CLInt
CLInt is a smart CLI generator from HELP message for Bash scripts

# Rationale

This work is strongly inspired by [Docopt](http://docopt.org/) Command-line interface description language.

I am a long time user of Docopt for Python and there is a version for Bash as well, but I do not like depending on external libraries at runtime when dealing with bash scripts.
**CLInt**, instead, works at write time, autogenerating the code that can be pasted inside the script itself.

NOTE: if *xclip* is installed in your system, CLInt's output is saved in the system clipbord to speed up copy&paste into your script.


# How it works

If your bash script contains a standard *usage* description but with double comment sign (##)
at the beginning of each line you are done. CLInt will read it and auto-generate all the *getopts* code
necessary to manage your options.


# How to use it

    usage: clint.sh -s <script_path> [-d]

    options:
         -s <script_path> The path to the script to be parsed
         -d               Enable debug logs [default:0]

as example, consider a script with this usage messge:

    ## Test script to show how clint.sh works
    ##
    ## usage: yourscript ... # the usual usage line message (CLInt ignores this part)
    ##
    ## options:              # The options part (CLInt parses this part. Be aware of the format)
    ##      -f, --file <string>      Example of a valued flag. The flag's value is stored in a variable named "$_file"
    ##      -d, --default <string>   Example of a valued flag with a default value (_this_is_the_default) [default: _this_is_the_default]
    ##      -b, --boolean            Example of a no-argument (boolean) flag: its value (0 or 1) is stored in a variable named "$_boolean"
    ##      -v, --verbose            Example of a no-argument (boolean) flag with a default value "0" [default: 0]

Now, executing clint.sh you'll get:

    $ clint.sh -s test-script.sh

    # GENERATED_CODE: start
    # Default values
    _verbose=0
    _default=_this_is_the_default

    # No-arguments is not allowed
    [ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1

    # Converting long-options into short ones
    for arg in "$@"; do
      shift
      case "$arg" in
    "--file") set -- "$@" "-f";;
    "--default") set -- "$@" "-d";;
    "--boolean") set -- "$@" "-b";;
    "--verbose") set -- "$@" "-v";;
      *) set -- "$@" "$arg"
      esac
    done

    function print_illegal() {
        echo Unexpected flag in command line \"$@\"
    }

    # Parsing flags and arguments
    while getopts 'hbvf:d:' OPT; do
        case $OPT in
            h) sed -ne 's/^## \(.*\)/\1/p' $0
               exit 1 ;;
            b) _boolean=1 ;;
            v) _verbose=1 ;;
            f) _file=$OPTARG ;;
            d) _default=$OPTARG ;;
            \?) print_illegal $@ >&2;
                echo "---"
                sed -ne 's/^## \(.*\)/\1/p' $0
                exit 1
                ;;
        esac
    done
    # GENERATED_CODE: end

Note:

The following part of the script has been automatically added because *not all the arguments have a default value*.

    # No-arguments is not allowed
    [ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1

and it prevents the script to run without the mandatory arguments. As example, if you run the script with no args, you get

    $ ./test-script.sh
    Test script to show how clint.sh works
    usage: yourscript ... # the usual usage line message (CLInt ignores this part)
    options:              # The options part (CLInt parses this part. Be aware of the format)
         -f, --file <string>      Example of a flag with argument. The flag's value is stored in a variable named "$_file"
         -d, --default <string>   Example of a valued flag with a default value (_this_is_the_default) [default: _this_is_the_default]
         -b, --boolean            Example of a no-argument (boolean) flag: its value (0 or 1) is stored in a variable named "$_boolean"
         -v, --verbose            Example of a no-argument (boolean) flag with a default value "0" [default: 0]
