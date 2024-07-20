#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
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

    # Iterate through each top-level key in the JSON
    for section in $JSON_KEYS; do

        # Remove digits from the end of the section name to get the script name
        base_section_name=$(echo "$section" | grep -o '^[a-zA-Z_-]*')
        # script_name="output_${base_section_name}.sh"

        # Extract the run value
        RUN=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].run')
        FILENAME=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].filename')
        TEXT=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].text')
        PERMISSIONS=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].permissions')

        printf "🗒️ %-10s : %s\n" "TextFile" "${FILENAME}"

        if [[ ${FILENAME} == "" ]]; then echo "No Filename given. Using Default. textfile.txt"; FILENAME="textfile.txt"; fi
        if [[ ${PERMISSIONS} == "" ]]; then PERMISSIONS="400"; fi

        echo $TEXT > $FILENAME
        chmod $PERMISSIONS $FILENAME 
        
    done
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