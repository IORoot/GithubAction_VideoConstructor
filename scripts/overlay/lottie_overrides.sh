#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯


# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 -t [TARGET] \n\n" >&2 

        printf "Summary:\n"
        printf "This will search & replace text in a file.\n\n"

        printf "Flags:\n"

        printf " --lottiefile <TARGET>\n"
        printf "\tInput Lottie JSON File.\n\n"

        printf " --json <JSON>\n"
        printf "\tJSON File of each search/replace fields.\n\n"

        exit 1
    fi
}


# ╭──────────────────────────────────────────────────────────╮
# │         Take the arguments from the command line         │
# ╰──────────────────────────────────────────────────────────╯
function arguments()
{
    POSITIONAL_ARGS=()

    while [[ $# -gt 0 ]]; do
    case $1 in


        --lottiefile)
            INPUT="$2"
            shift
            shift
            ;;


        --json)
            JSON="$2"
            shift 
            shift
            ;;



        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;



        *)
            POSITIONAL_ARGS+=("$1") # save positional arg back onto variable
            shift                   # remove argument and shift past it.
            ;;
    esac
    done

}


# ╭──────────────────────────────────────────────────────────╮
# │     Run these checks before you run the main script      │
# ╰──────────────────────────────────────────────────────────╯
function pre_flight_checks()
{

    if [[ -z "${INPUT+x}" ]]; then 
        printf "❌ No INPUT FILE specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${JSON+x}" ]]; then 
        printf "❌ No JSON FILE specified. Exiting.\n"
        exit 1
    fi


}


# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks
    

}

usage "$@"
arguments "$@"
main "$@"