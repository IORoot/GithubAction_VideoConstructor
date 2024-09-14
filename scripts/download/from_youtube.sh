#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/download"
SUBTITLES_FOLDER="./scripts/subtitles"
PWD=$(pwd)
EXT="srt"
COOKIE_FILE="cookies.txt"
USERAGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will download any youtube video listed.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

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

}

function read_config()
{
    URL=$(cat $JSON | jq -r -c '.url')
    SUBTITLES=$(cat $JSON | jq -r -c '.subtitles')  
    DEDUPE=$(cat $JSON | jq -r -c '.dedupe')  
    DYNAMICTEXT=$(cat $JSON | jq -r -c '.dynamictext')  
}



function download()
{
    SUBTITLE_STRING=""
    if [ -n "${SUBTITLES}" ]; then
        SUBTITLE_STRING=" --write-subs --write-auto-subs --sub-lang en --convert-subs=srt "
    fi 

    OUTPUT=$(yt-dlp --cookies $COOKIE_FILE ${SUBTITLE_STRING} -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' -o "youtube_%(id)s.%(ext)s" ${URL} --user-agent \"${USERAGENT}\" --extractor-args "youtube:player-client=web,default;po_token=web+MnTDjl30_DR2RsO2J1t_PGkbRZtuuJ7eiVsc-FMqTAHKF1XqK6np9FDiO8hB8nAk4vd9Q7UFjc3YaZ6Zbbewi6wwYPL34lz7yiUiwPaypZEiaxtDy3YwjOcjy794g8LAA15tymrBlBgC5cWIS2eWa8U1PbZWlw==")

    echo $OUTPUT

    OUTPUT_FILENAME=$(echo "$OUTPUT" | sed -n 's/.*Writing video subtitles to: \(youtube_[^ ]*\)\.vtt.*/\1/p').$EXT

    echo "OUTPUT_FILENAME:$OUTPUT_FILENAME"

}



function remove_duplicates()
{
    echo "Run DEDUPE:${DEDUPE}"
    if [[ "${DEDUPE}" = "true" ]]; then
        bash $SUBTITLES_FOLDER/remove_dupes.sh $OUTPUT_FILENAME
    fi
}



function dynamic_text()
{
    echo "Run DYNAMICTEXT:${DYNAMICTEXT}"
    if [[ "${DYNAMICTEXT}" = "true" ]]; then
        bash $SUBTITLES_FOLDER/dynamic_subs.sh $OUTPUT_FILENAME 
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

    read_config
    
    printf "📥 %-10s : %s\n" "YouTube" "$video_id"

    download

    remove_duplicates

    dynamic_text

}

usage "$@"
arguments "$@"
main "$@"
