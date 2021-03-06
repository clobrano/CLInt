# CLInt
CLInt is a smart CLI generator from HELP message for Bash scripts

# Rationale

This work is strongly inspired by [Docopt](http://docopt.org/) Command-line interface description language.

I am a long time user of Docopt for Python and there is [a version for Bash](https://github.com/docopt/docopts) as well (which is great), but Bash scripting (from my point of view) is different than Python or other languages.
Scripts are usually copied into remote machines and shared easily without the need to install any dependency, so I prefer not to depend on external libraries/tools at runtime when dealing with bash scripts.

**CLInt works at writing time, autogenerating all the bash code needed to parse the command line options.**


# How it works

Your bash script only needs a *usage* description (do you have a usage description, right?) **with double comment sign ## at the beginning of each line**, then CLInt parses it and auto-generates all the code necessary to manage your options.


# How to use it

This is CLInt's usage description. CLInt (of course), used itself to generate its own option parsing code.

    ## Helper script to autogenerate getopts code out of the target script's help message
    ## The script must contain a usage description with '##' at the beginning of each line (that is, like this one)
    ##
    ## usage: clint.sh [options]
    ## options:
    ##      -s, --script <path> The path to the script to be parsed
    ##      -d, --debug         Enable debug logs [default:0]


As example, consider a script with this usage description:

    ## Test script to show how clint.sh works
    ##
    ## usage: yourscript ... # the usage message (CLInt ignores this part)
    ##
    ## options:              # The options part (CLInt parses this part. Be aware of the format)
    ##      -f, --file <string>      Example of a valued flag. The flag's value is stored in a variable named "$_file"
    ##      -d, --default <string>   Example of a valued flag with a default value (_this_is_the_default) [default: _this_is_the_default]
    ##      -b, --boolean            Example of a no-argument (boolean) flag: its value (0 or 1) is stored in a variable named "$_boolean"
    ##      -v, --verbose            Example of a no-argument (boolean) flag with a default value "0" [default: 0]

Run `clint.sh` and you'll get:

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

Copy paste this code into `test-script.sh`, that's it.

NOTE: if *xclip* is installed in your system, CLInt's output is saved in the system clipbord to speed up copy&paste into your script.

Let's dig into the autogenerated code:

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

If any options have a default value, this piece of code disappear, allowing the script to run without arguments, using the default behavior

# Contributions
I am really happy to consider, discuss and accept any PR that can make CLInt better.
