#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/download"
PWD=$(pwd)
SEARCHRESULTS=""


# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json] \n\n" >&2 

        printf "Summary:\n"
        printf "This will switch the download to the correct script.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

        printf " --searchresults <FILE>\n"
        printf "\tThe file to read with the searchresults.\n\n"

        printf " --rclone <CONFIG_FILE>\n"
        printf "\tThe rclone config file to access Google Drive.\n\n"

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


        --searchresults)
            SEARCHRESULTSFILE="$2"
            shift
            shift
            ;;


        --rclone)
            RCLONECONFIGFILE="$2"
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


# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks

    JSON_CONTENT=$(cat "$JSON")

    # Iterate through each top-level key in the JSON
    for section in $(echo "$JSON_CONTENT" | jq -r 'keys[]'); do

        # Remove digits from the end of the section name to get the script name
        base_section_name=$(echo "$section" | grep -o '^[a-zA-Z_-]*')
        script_name="${base_section_name}.sh"

        # Extract the run value
        run=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].run')


        if [[ $base_section_name == 'from_search' && $run == true ]]; then
            if [ -z ${SEARCHRESULTSFILE+x} ]; then echo "No Search Results file given. Skipping."; return 0; fi
            SEARCHRESULTSFLAG="--searchresults ${SEARCHRESULTSFILE}"
        fi


        if [[ $base_section_name == 'from_gdrive' && $run == true ]]; then
            if [ -z ${RCLONECONFIGFILE+x} ]; then echo "No Rclone Config file given. Skipping."; return 0; fi
            SEARCHRESULTSFLAG="--config ${RCLONECONFIGFILE}"
        fi


        # Proceed only if run is true
        if [ "$run" == true ]; then
            echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section]' > $PWD/download_${section}.json
            bash $FOLDER/$script_name --json $PWD/download_${section}.json $SEARCHRESULTSFLAG
        fi
        
        # reset
        SEARCHRESULTSFLAG=""
    done

}

usage "$@"
arguments "$@"
main "$@"