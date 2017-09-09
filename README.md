# optgen.sh
Getopt smart generator from HELP message in bash

# Rationale

This work is strongly inspired by [Docopt](http://docopt.org/) Command-line interface description language.

I am a long time user of Docopt for Python and there is a version for Bash as well,
but I do not like depending on external libraries at runtime for bash scripts.
**Optgen**, instead, works at write time, autogenerating the code you need to manage the input
arguments inside the script itself.

NOTE: if *xclip* is installed in your system, Optgen's output is automatically copied in your
system clipbord for faster pasting in your script.


# How it works

If your bash script contains a standard *usage* description but with double comment sign (##)
at the beginning of each line you are done. Optgen reads it and generates the *getopt* code
out your script's options


# How to use it
  
    usage: getopt.sh -s <script_path> [-d]

    options:
         -s <script_path> The path to the script to be parsed
         -d               Enable debug logs [default:0]

as exampe, consider a script with this usage messge:

    ## Test script to show how optgen.sh works
    ## usage: yourscript ... <- this line is actually ignored
    ##
    ## options: <- this is the important part
    ##      -a <a_value>   flag with argument: its value is stored in variable named "$_a_value"
    ##      -b             no-argument flag: its value (0 or 1) is stored in a variable "$_b" 
    ##      -c <c_value>   like flag -a, but with a default value "ok" [default: ok]
    ##      -d             like flag -b, but with a default value "0" [default: 0]
    
Now, executing optgen.sh you'll get:
    
    $ optgen.sh -s test-script.sh

    # Default values
    _c_value=ok
    _d=0
    
    # No-arguments is not allowed
    [ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1
    
    # Parsing flags and arguments
    while getopts 'ha:c:bd' OPT; do
        case $OPT in
            h)
                sed -ne 's/^## \(.*\)/\1/p' $0
                exit 1
                ;;
            a)
                _a_value=$OPTARG
                ;;
            c)
                _c_value=$OPTARG
                ;;
            b)
                _b=1
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

Note:

The following part of the script has been added because not all the 
arguments have a default value

    # No-arguments is not allowed
    [ $# -eq 0 ] && sed -ne 's/^## \(.*\)/\1/p' $0 && exit 1
 
