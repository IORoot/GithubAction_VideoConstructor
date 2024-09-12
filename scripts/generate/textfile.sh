#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
OUTPUT_FOLDER="./assets/"
FOLDER="./scripts/generate"
PWD=$(pwd)


# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json] \n\n" >&2 

        printf "Summary:\n"
        printf "This will switch the output to the correct script.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

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
    
    if [ ! -f "$JSON" ]; then
        printf "No file found."
    fi

}

# ╭───────────────────────────────────────────────────────╮
# │     Loop through JSON and create textfile on each      │
# ╰───────────────────────────────────────────────────────╯
function create_textfile()
{
    JSON_CONTENT=$(cat "$JSON")
    JSON_KEYS=$(echo "$JSON_CONTENT" | jq -r 'keys[]')

    # Extract the run value
    RUN=$(echo "$JSON_CONTENT" | jq -r '.run')
    FILENAME=$(echo "$JSON_CONTENT" | jq -r '.filename')
    TEXT=$(echo "$JSON_CONTENT" | jq -r '.text')
    PERMISSIONS=$(echo "$JSON_CONTENT" | jq -r '.permissions')

    printf "🗒️ %-10s : %s\n" "TextFile" "${FILENAME}"
    printf "🗒️ %-10s : %s\n" "Text" "${TEXT}"

    if [[ ${FILENAME} == "" ]]; then echo "No Filename given. Using Default. textfile.txt"; FILENAME="textfile.txt"; fi
    if [[ ${PERMISSIONS} == "" ]]; then PERMISSIONS="400"; fi

    if [[ "$RUN" == "true" ]]; then
        echo "${TEXT}" > $FILENAME
        chmod $PERMISSIONS $FILENAME

        if [ -d "$OUTPUT_FOLDER" ]; then
            mv $FILENAME $OUTPUT_FOLDER
        fi
        
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

    create_textfile

}

usage "$@"
arguments "$@"
main "$@"