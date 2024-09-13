#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/download"
SNIPPETFOLDER="./scripts/snippets"
PWD=$(pwd)
SEARCHRESULTS=""
COOKIE_FILE="cookies.txt"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json] --searchresults [searchresultfile.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will download snippets (using yt_snippets.sh) from any youtube video listed in the searchresults file.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

        printf " --searchresults <FILE>\n"
        printf "\tThe JSON file to read with the searchresults.\n\n"

        printf " --cookies <FILE>\n"
        printf "\tThe cookies file to read for authentication to youtube.\n\n"

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


        --cookies)
            COOKIE_FILE="$2"
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
        printf "No config file found."
    fi    

    if [ ! -f "$SEARCHRESULTSFILE" ]; then
        printf "No results file file found."
    fi

}

function read_config()
{
    COUNT=$(cat $JSON | jq -r -c '.count')
    DURATION=$(cat $JSON | jq -r -c '.duration')
    TIMESTAMPS=$(cat $JSON | jq -r -c '.timestamps')
    SUBTITLES=$(cat $JSON | jq -r -c '.subtitles')
}



function download_subtitles()
{
    yt-dlp https://www.youtube.com/watch?v=${video_id} --cookies $COOKIE_FILE --skip-download --write-subs --write-auto-subs --sub-lang en --convert-subs=srt -o "subtitle_%(id)s"
}



# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks

    read_config

    cat $SEARCHRESULTSFILE | jq -r -c '.results[] | .video' | while read -r video; do

        video_id=$(echo "$video" | sed 's/^.*=//' | cut -d'&' -f1)
        
        printf "📥 %-10s : %s\n" "Snippet" "$video_id"

        command="${SNIPPETFOLDER}/yt_snippets.sh --videoid $video_id --count ${COUNT} --duration ${DURATION} --cookies ${COOKIE_FILE}"
        
        if [ -n "${TIMESTAMPS}" ]; then
            command+=" --timestamps ${TIMESTAMPS}"
        fi    

        echo $command
        
        eval "$command"

        # Download subtitles if on.
        if [ -n "${SUBTITLES}" ]; then
            download_subtitles
        fi 

    done

}

usage "$@"
arguments "$@"
main "$@"
