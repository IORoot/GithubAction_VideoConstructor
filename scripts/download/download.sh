#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/download"
PWD=$(pwd)
SEARCHRESULTS=""
COOKIE_FILE="cookies.txt"
OUTDIR="./assets/"  

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

        printf " --cookies <FILE>\n"
        printf "\tThe cookies file to read for authentication to youtube.\n\n"

        printf " --outdir <FILE>\n"
        printf "\tThe output directory.\n\n"
        

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


        --cookies)
            COOKIE_FILE="$2"
            shift
            shift
            ;;


        --outdir)
            OUTDIR="$2"
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

    # MAKE SURE / on end of output directory.
    if [[ -n "$OUTDIR" && "${OUTDIR: -1}" != "/" ]]; then
        OUTDIR="${OUTDIR}/"
    fi

    JSON_CONTENT=$(cat "$JSON")

    # Iterate through each top-level key in the JSON
    for section in $(echo "$JSON_CONTENT" | jq -r 'keys[]'); do

        # Remove digits from the end of the section name to get the script name
        base_section_name=$(echo "$section" | grep -o '^[a-zA-Z_-]*')
        script_name="${base_section_name}.sh"

        # Extract the run value
        run=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].run')


        if [[ $base_section_name == 'from_youtube' && $run == true ]]; then
            if [ -z ${COOKIE_FILE+x} ]; then echo "No Cookies file given. Skipping."; return 0; fi
            FLAGS="--cookies ${COOKIE_FILE}"
        fi


        if [[ $base_section_name == 'from_search' && $run == true ]]; then
            if [ -z ${SEARCHRESULTSFILE+x} ]; then echo "No Search Results file given. Skipping."; return 0; fi
            if [ -z ${COOKIE_FILE+x} ]; then echo "No Cookies file given. Skipping."; return 0; fi
            FLAGS="--searchresults ${SEARCHRESULTSFILE} --cookies ${COOKIE_FILE}"
        fi


        if [[ $base_section_name == 'from_gdrive' && $run == true ]]; then
            if [ -z ${RCLONECONFIGFILE+x} ]; then echo "No Rclone Config file given. Skipping."; return 0; fi
            FLAGS="--config ${RCLONECONFIGFILE}"
        fi


        # Proceed only if run is true
        if [ "$run" == true ]; then
            echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section]' > $PWD/download_${section}.json
            bash $FOLDER/$script_name --json $PWD/download_${section}.json $FLAGS --outdir $OUTDIR
        fi
        
        # reset
        FLAGS=""
    done

}

usage "$@"
arguments "$@"
main "$@"