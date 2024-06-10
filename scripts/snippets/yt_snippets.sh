#!/bin/bash
# ╭──────────────────────────────────────────────────────────────────────────────╮
# │                                                                              │
# │     Return the timestamps of the most popular parts of a youtube video       │
# │                                                                              │
# ╰──────────────────────────────────────────────────────────────────────────────╯

# ╭──────────────────────────────────────────────────────────╮
# │                       Set Defaults                       │
# ╰──────────────────────────────────────────────────────────╯

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
URL="https://yt.lemnoslife.com/videos?part=mostReplayed&id="
COUNT=1
DURATION=5
DURATION_MILLISECONDS=5000

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 2 ]; then
        printf "ℹ️ Usage:\n $0 -v <YOUTUBE_VIDEO_ID> -n <NUMBER>\n\n" >&2 

        printf "Summary:\n"
        printf "Downloads the snippets of videos.\n\n"

        printf "Flags:\n"

        printf " -v | --videoid <YOUTUBE_VIDEO_ID>\n"
        printf "\tSupply the youtube video ID to scan.\n\n"

        printf " -c | --count <NUMBER>\n"
        printf "\tNumber of timestamps to return (most watched first).\n\n"

        printf " -d | --duration <NUMBER>\n"
        printf "\tNumber of timestamps to return (most watched first).\n\n"

        printf " -t | --timestamps <CSV_TIMESTAMPS>\n"
        printf "\tComma separated list of timestamps in seconds. no spaces.\n\n"

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

        -v|--videoid)
            YOUTUBE_VIDEO_ID="$2"
            shift
            shift
            ;;


        -c|--count)
            COUNT="$2"
            shift
            shift
            ;;

        -d|--duration)
            DURATION="$2"
            DURATION_MILLISECONDS=$(($DURATION * 1000))
            shift
            shift
            ;;

        -t|--timestamps)
            TIMESTAMPS="$2"
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



# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │     Function to convert milliseconds to timestamp     │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
milliseconds_to_timestamp() {
    local milliseconds="$1"
    local seconds=$((milliseconds / 1000))
    local milliseconds_remainder=$((milliseconds % 1000))

    if [ "$(uname)" == "Darwin" ]; then
        # For macOS
        timestamp=$(date -u -r $seconds +"%T")
    else
        # For Linux
        timestamp=$(date -u -d "@$seconds" +"%T")
    fi

    RETURN_TIMESTAMP="${timestamp}.${milliseconds_remainder}"
}

# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │    DETERMINE THE SOURCE URL FOR THE YOUTUBE VIDEO     │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
function get_best_url()
{

    BEST_VIDEO_URL=$(yt-dlp --get-url -f b "https://www.youtube.com/watch?v=$YOUTUBE_VIDEO_ID")

}

# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │         GET THE MOST PLAYED PARTS OF A VIDEO          │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
function get_most_played()
{

    # Send the request to get the MOST REPLAYED timestamps
    JSON_RESPONSE=$(curl -s "${URL}${YOUTUBE_VIDEO_ID}")
    MOST_REPLAYED=$(echo "$JSON_RESPONSE" | jq -r '.items[0].mostReplayed')


    # OVERRIDE with the custom set timestamps.
    if [ -n "$TIMESTAMPS" ]; then
        IFS=',' read -ra SECONDS_ARRAY <<< "$TIMESTAMPS"
        MOST_PLAYED_PARTS=""
        for seconds in "${SECONDS_ARRAY[@]}"; do
            milliseconds=$((seconds * 1000))
            MOST_PLAYED_PARTS+="$milliseconds"$'\n'
        done
        return
    fi

    # If null, separate by 30 seconds.
    if [ "$MOST_REPLAYED" == "null" ]; then
        echo "--- No MOST_REPLAYED found - defaulting to 30sec increments from 0."
        MOST_PLAYED_PARTS=""
        for ((i = 0; i < COUNT; i++)); do
            value=$((i * 30000))
            MOST_PLAYED_PARTS+="$value"$'\n'
        done
        return
    fi


    # Read the JSON file and parse the top N highest intensity scores with their startMillis values
    if [ "$MOST_REPLAYED" != "null" ]; then
        MOST_PLAYED_PARTS=$(echo "$MOST_REPLAYED" | jq -r --argjson num "$COUNT" '.markers | sort_by(-.intensityScoreNormalized) | .[:$num] | map({startMillis}) | .[] | "\(.startMillis)"')
        return
    fi


}


# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │         DOWNLOAD JUST THE SNIPPETS USING MPV          │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
function get_all_snippets()
{

    # Create a bash array from the output of jq
    declare -a MILLISECOND_ARRAY
    while read -r startMillis intensityScoreNormalized; do
        MILLISECOND_ARRAY+=("$startMillis")
    done <<< "$MOST_PLAYED_PARTS"

    # LOOP through each entry
    for MILLISECONDS in "${MILLISECOND_ARRAY[@]}"; do

        if [ "$MILLISECONDS" == "" ]; then continue; fi

        # Calculate start timestamp
        milliseconds_to_timestamp $MILLISECONDS
        START_TIMESTAMP=$RETURN_TIMESTAMP

        # Calculate end timestamp
        END_MILLISECONDS=$(($MILLISECONDS + $DURATION_MILLISECONDS))
        milliseconds_to_timestamp $END_MILLISECONDS
        END_TIMESTAMP=$RETURN_TIMESTAMP

        # Run your command for each millisecond value
        echo "Getting $YOUTUBE_VIDEO_ID snippet: $START_TIMESTAMP to $END_TIMESTAMP. File: ${YOUTUBE_VIDEO_ID}_${START_TIMESTAMP}.mp4"

        # download_snippet
        download_snippet $START_TIMESTAMP $END_TIMESTAMP

    done

}


# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │    Download a video snippet at specific timestamp      │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
function download_snippet()
{

    START_TIMESTAMP=$1
    END_TIMESTAMP=$2
    FILENAME="${YOUTUBE_VIDEO_ID}_${START_TIMESTAMP}.mp4"

    mpv --no-terminal --start=${START_TIMESTAMP} --end=${END_TIMESTAMP} --o=${FILENAME} "$BEST_VIDEO_URL"

}



# ╭────────────────────────────────────────────────────────╮
# │                                                        │
# │                      Main Function                     │
# │                                                        │
# ╰────────────────────────────────────────────────────────╯
function main()
{

    # Step 1 - Use yt-dlp to get the source URL for youtube video at correct format 
    get_best_url 

    # Step 2 - Use https://yt.lemnoslife.com to get the most-played sections from video
    get_most_played

    # Step 3 - Use mpv to download JUST that snippet of video for the source address
    get_all_snippets
    
}

usage $@
arguments $@
main $@