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

        printf " --overridefile <JSON>\n"
        printf "\tOverride JSON File of each search/replace fields.\n\n"

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
            LOTTIEFILE="$2"
            shift
            shift
            ;;


        --overridefile)
            OVERRIDEFILE="$2"
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

    if [[ -z "${LOTTIEFILE+x}" ]]; then 
        printf "❌ No INPUT FILE specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${OVERRIDEFILE+x}" ]]; then 
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

    printf "SED Replacement in lottie JSON files\n"
    
    cat ${OVERRIDEFILE} | jq -c '.[]' | while read -r override; do

        lottie_search=$(echo "$override" | jq -r '.lottie_search')
        lottie_replacement=$(echo "$override" | jq -r '.lottie_replacement')
        lottie_global=$(echo "$override" | jq -r '.lottie_global')

        # Escape special characters in search and replacement strings
        escaped_search=$(printf '%s\n' "$lottie_search" | sed -e 's/[]\/$*.^[]/\\&/g')
        escaped_replacement=$(printf '%s\n' "$lottie_replacement" | sed -e 's/[&/\]/\\&/g')

        # Set sed flags for global or non-global replacement
        if [ "$lottie_global" = "true" ]; then
            sed_flag="g"
        else
            sed_flag=""
        fi

        # Perform sed search and replace
        # Detect the OS and set the appropriate sed command
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            echo sed -i '' -e "s/${escaped_search}/${escaped_replacement}/${sed_flag}" "${LOTTIEFILE}"
            sed -i '' -e "s/${escaped_search}/${escaped_replacement}/${sed_flag}" "${LOTTIEFILE}"
        else
            # Linux and other Unix-like systems
            echo sed -i -e "s/${escaped_search}/${escaped_replacement}/${sed_flag}" "${LOTTIEFILE}"
            sed -i -e "s/${escaped_search}/${escaped_replacement}/${sed_flag}" "${LOTTIEFILE}"
        fi

    done

}

usage "$@"
arguments "$@"
main "$@"