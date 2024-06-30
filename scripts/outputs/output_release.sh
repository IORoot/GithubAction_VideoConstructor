#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
PWD=$(pwd)
FILELIST="./output_filelist.txt"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will send a webhook request to Wordpress PostPlanPro Release.\n\n"

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
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    cat $JSON
    # Get the folder to upload onto google drive
    URL=$(cat $JSON | jq -r -c '.url')
    TOKEN=$(cat $JSON | jq -r -c '.token')
    SCHEDULE=$(cat $JSON | jq -r -c '.schedule')
    TITLE=$(cat $JSON | jq -r -c '.title')
    CONTENT=$(cat $JSON | jq -r -c '.content')

    VIDEO_URL=$(cat $FILELIST | grep SSHVIDEO | tail -n 1 | cut -d ':' -f 2-)
    THUMBNAIL_URL=$(cat $FILELIST | grep SSHIMAGE | tail -n 1 | cut -d ':' -f 2-)
    GDRIVE_FOLDER=$(cat $FILELIST | grep GDRIVE | tail -n 1 | cut -d ':' -f 2-)
    GDRIVE_FOLDER=$(dirname "$GDRIVE_FOLDER")

    if [[ $URL != *"/wp-json/custom/v1/release"* ]]; then
        URL="${URL%/}/wp-json/custom/v1/release"
    fi

    # Send Request to PostPlanPro
    curl -X POST ${URL} \
    -H "Content-Type: application/json" \
    -H "X-API-TOKEN: ${TOKEN}" \
    -d "{
        \"title\": \"${TITLE}\",
        \"content\": \"${CONTENT}\",
        \"acf\": {
            \"ppp_release_method\": \"true\",
            \"ppp_release_schedule\": \"${SCHEDULE}\",
            \"ppp_video_url\": \"${VIDEO_URL}\",
            \"ppp_thumbnail_url\": \"${THUMBNAIL_URL}\",
            \"ppp_gdrive_folder\": \"${GDRIVE_FOLDER}\"
        }
    }"

    # Message
    printf "\n"
    printf "📬 %-10s : %s\n" "RELEASE" "$URL"
}

usage "$@"
arguments "$@"
main "$@"
