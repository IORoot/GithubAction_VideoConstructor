#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
RELEASE_TITLE=""
RELEASE_CONTENT=""

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 -t [TARGET] \n\n" >&2 

        printf "Summary:\n"
        printf "This will send a curl request to the target to generate a release.\n\n"

        printf "Flags:\n"

        printf " --target <TARGET>\n"
        printf "\tTarget URL of REST API.\n\n"

        printf " --token <TOKEN>\n"
        printf "\tAccess token to use REST API.\n\n"

        printf " --schedule <RELEASE_SCHEDULE>\n"
        printf "\tName of the schedule to apply to release.\n\n"

        printf " --title <RELEASE_TITLE>\n"
        printf "\tTitle of the release.\n\n"

        printf " --content <RELEASE_CONTENT>\n"
        printf "\tContent of the release.\n\n"

        printf " --gdrive <GDRIVE>\n"
        printf "\tGoogle Drive Folder.\n\n"

        printf " --video <VIDEO_URL>\n"
        printf "\tVideo URL.\n\n"

        printf " --thumbnail <THUMBNAIL_URL>\n"
        printf "\tThumbnail URL.\n\n"

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


        --target)
            TARGET="$2"
            shift
            shift
            ;;


        --token)
            TOKEN="$2"
            shift 
            shift
            ;;


        --schedule)
            RELEASE_SCHEDULE="$2"
            shift 
            shift
            ;;


        --title)
            RELEASE_TITLE="$2"
            shift 
            shift
            ;;


        --content)
            RELEASE_CONTENT="$2"
            shift 
            shift
            ;;


        --gdrive)
            GDRIVE="$2"
            shift 
            shift
            ;;


        --video)
            VIDEO_URL="$2"
            shift 
            shift
            ;;


        --thumbnail)
            THUMBNAIL_URL="$2"
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

    if [[ -z "${TARGET+x}" ]]; then 
        printf "❌ No TARGET specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${TOKEN+x}" ]]; then 
        printf "❌ No TOKEN specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${RELEASE_SCHEDULE+x}" ]]; then 
        printf "❌ No RELEASE SCHEDULE specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${GDRIVE+x}" ]]; then 
        printf "❌ No GDRIVE specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${VIDEO_URL+x}" ]]; then 
        printf "❌ No VIDEO_URL specified. Exiting.\n"
        exit 1
    fi

    if [[ -z "${THUMBNAIL_URL+x}" ]]; then 
        printf "❌ No THUMBNAIL_URL specified. Exiting.\n"
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

    curl -X POST ${TARGET} \
    -H "Content-Type: application/json" \
    -H "X-API-TOKEN: ${TOKEN}" \
    -d "{
        \"title\": \"${RELEASE_TITLE}\",
        \"content\": \"${RELEASE_CONTENT}\",
        \"acf\": {
            \"ppp_release_method\": \"true\",
            \"ppp_release_schedule\": \"${RELEASE_SCHEDULE}\",
            \"ppp_video_url\": \"${VIDEO_URL}\",
            \"ppp_thumbnail_url\": \"${THUMBNAIL_URL}\",
            \"ppp_gdrive_folder\": \"${GDRIVE}\"
        }
    }"
}

usage "$@"
arguments "$@"
main "$@"