#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
PWD=$(pwd)
CONFIG="./config.json"
UPLOADS_FOLDER="./uploads"
FOLDER_PREFIX="videoconstructor"
OUTPUT_FILELIST="./output_filelist.txt"
OUTPUT_FILELIST_JSON="./output_filelist.json"
WEBHOOK_DATA="./webhook_data.json"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will send a webhook.\n\n"

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



function create_json_file()
{
    echo "{" > $OUTPUT_FILELIST_JSON
    echo "  \"output_files\": {" >> $OUTPUT_FILELIST_JSON
    first=true

    while IFS=: read -r key path; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> $OUTPUT_FILELIST_JSON
    fi
    echo "  \"$key\": \"$path\"" >> $OUTPUT_FILELIST_JSON
    done < $OUTPUT_FILELIST

    echo "" >> $OUTPUT_FILELIST_JSON
    echo "  }" >> $OUTPUT_FILELIST_JSON
    echo "}" >> $OUTPUT_FILELIST_JSON
}


function combine_with_config
{
    jq -s 'add' $CONFIG $OUTPUT_FILELIST_JSON > $WEBHOOK_DATA
}

# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    # Get the folder to upload onto google drive
    URL=$(cat $JSON | jq -r -c '.url')

    # Create a JSON file from the output_filelist.txt file
    create_json_file

    # Conbine with the config the output_filelist.txt file
    combine_with_config

    DATA=$(cat $WEBHOOK_DATA)
    BASE64_DATA=$(cat $WEBHOOK_DATA | base64)

    # Send Webhook
    curl -X POST  -H "Content-Type: text/plain"  -d "$DATA" $URL

    # Message
    printf "\n"
    printf "📬 %-10s : %s\n" "Webhook" "$URL"
}

usage "$@"
arguments "$@"
main "$@"
