#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/music"
STRATEGY_FLAG="--playlist-random"

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



function read_config()
{
    SECTION=$1

    URL=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].url')
    STRATEGY=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].strategy')
    ITEMS=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].items')
    RANGE=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].range')
    TOP=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].top')
    BOTTOM=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].bottom')
    START=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].start')
    START_MILLI=$START".00"
    END=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].end')
    END_MILLI=$END".00"
    MAX=$(cat $JSON | jq -r --arg section "$SECTION" -c '.[$section].max')


    

}

# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks

    for section in $(cat "$JSON" | jq -r 'keys[]'); do

        read_config $section

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

        COMMAND="yt-dlp $URL $STRATEGY_FLAG --restrict-filenames --trim-filenames 20 --extract-audio --audio-format mp3 --postprocessor-args \"-ss $START_MILLI -t $END_MILLI\" --output music_%\(epoch\)s.mp3 --force-overwrites"
        echo $COMMAND

        eval "$COMMAND"

    done


}

usage "$@"
arguments "$@"
main "$@"



