#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/outputs"
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
        printf "This will switch the output to the correct script.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

        printf " --sshuser <SSHUSER>\n"
        printf "\tThe Username to use when uploading to server.\n\n"

        printf " --sshpass <SSHPASS>\n"
        printf "\tThe Password to use when uploading to server.\n\n"

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


        --rclone)
            RCLONECONFIGFILE="$2"
            shift
            shift
            ;;


        --sshuser)
            SSHUSER="$2"
            shift
            shift
            ;;


        --sshpass)
            SSHPASS="$2"
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
    JSON_KEYS=$(echo "$JSON_CONTENT" | jq -r 'keys[]')

    if [[ $JSON_KEYS == *"release"* ]]; then
        # Remove "release" from JSON_KEYS
        JSON_KEYS="${JSON_KEYS/release/}"
        # Append "release" to the end of JSON_KEYS
        JSON_KEYS="$JSON_KEYS release"
    fi

    # Iterate through each top-level key in the JSON
    for section in $JSON_KEYS; do

        # Remove digits from the end of the section name to get the script name
        base_section_name=$(echo "$section" | grep -o '^[a-zA-Z_-]*')
        script_name="output_${base_section_name}.sh"

        # Extract the run value
        run=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].run')


        # Google Drive Flags
        if [[ $base_section_name == 'gdrive' && $run == true ]]; then
            if [ -z ${RCLONECONFIGFILE+x} ]; then echo "No Rclone Config file given. Skipping."; return 0; fi
            FLAGS="--config ${RCLONECONFIGFILE}"
        fi

        # SSH Flags
        if [[ $base_section_name == 'ssh' && $run == true ]]; then
            FLAGS="--sshuser ${SSHUSER} --sshpass ${SSHPASS}"
        fi


        # Proceed only if run is true
        if [ "$run" == true ]; then
            echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section]' > $PWD/outputs_${section}.json
            bash $FOLDER/$script_name --json $PWD/outputs_${section}.json $FLAGS
        fi
        
        # reset
        FLAGS=""
    done

}

usage "$@"
arguments "$@"
main "$@"