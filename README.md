# CLInt
CLInt is a smart CLI generator from HELP message for Bash scripts

# Rationale

This work is strongly inspired by [Docopt](http://docopt.org/) Command-line interface description language.

I am a long time user of Docopt for Python and there is a version for Bash as well, but I do not like depending on external libraries at runtime when dealing with bash scripts.
**CLInt**, instead, works at write time, autogenerating the code that can be pasted inside the script itself.

NOTE: if *xclip* is installed in your system, CLInt's output is saved in the system clipbord to speed up copy&paste into your script.


# How it works

If your bash script contains a standard *usage* description but with double comment sign (##)
at the beginning of each line you are done. CLInt will read it and auto-generate all the *getopt* code
necessary to manage your options.


# How to use it
  
    usage: clint.sh -s <script_path> [-d]

    options:
         -s <script_path> The path to the script to be parsed
         -d               Enable debug logs [default:0]

as example, consider a script with this usage messge:

    ## Test script to show how clint.sh works
    ##
    ## usage: yourscript ...
    ##
    ## options: <- this is the important part
    ##      -a <a_value>   flag with argument: its value is stored in variable named "$_a_value"
    ##      -b             no-argument flag: its value (0 or 1) is stored in a variable "$_b" 
    ##      -c <c_value>   like flag -a, but with a default value "ok" [default: ok]
    ##      -d             like flag -b, but with a default value "0" [default: 0]
    
Now, executing clint.sh you'll get:
    
    $ clint.sh -s test-script.sh

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
 
so, if you run test-script.sh without arguments (as well as with -h flag) you'll get:

    $ ./test-script.sh 
    Test script to show how clint.sh works
    usage: yourscript ...
    options:    <- this is the important part
         -a <a_value>   flag with argument. It's value is stored in "$_a_value"
         -b             no-argument flag. It's value (0 or 1) is stored in "$_b" 
         -c <c_value>   like flag -a, but with a default value "ok" [default: ok]
         -d             like flag -b, but with a default value "0" [default: 0]
