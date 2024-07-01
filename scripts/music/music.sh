#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/music"
STRATEGY_FLAG=""

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json] \n\n" >&2 

        printf "Summary:\n"
        printf "This will download music.\n\n"

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


# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks

    LOOP=1

    for section in $(cat "$JSON" | jq -r 'keys[]'); do

        URL=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].url')
        STRATEGY=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].strategy')
        ITEMS=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].items')
        RANGE=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].range')
        TOP=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].top')
        BOTTOM=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].bottom')
        START=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].start')
        START_MILLI=$START".00"
        END=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].end')
        END_MILLI=$END".00"
        MAX=$(cat $JSON | jq -r --arg section "$section" -c '.[$section].max')

        echo $section
        echo $URL

        if [ $STRATEGY == "random" ]; then
            STRATEGY_FLAG="--playlist-random --max-downloads $MAX"
        fi

        if [[ $STRATEGY == "specific" ]]; then
            STRATEGY_FLAG="--playlist-items $ITEMS"
        fi

        if [[ $STRATEGY == "top" ]]; then
            STRATEGY_FLAG="--playlist-start $TOP"
        fi 

        if [[ $STRATEGY == "bottom" ]]; then
            STRATEGY_FLAG="--playlist-end  $BOTTOM"
        fi 

        COMMAND="yt-dlp -vU $URL $STRATEGY_FLAG --restrict-filenames --trim-filenames 20 --extract-audio --audio-format mp3 --postprocessor-args \"-ss $START_MILLI -t $END_MILLI\" --output music_${section}_%\(autonumber\)s.mp3 --force-overwrites"

        echo $COMMAND

        eval "$COMMAND"

        STRATEGY_FLAG=""
        ((LOOP++))
    done


}

usage "$@"
arguments "$@"
main "$@"



