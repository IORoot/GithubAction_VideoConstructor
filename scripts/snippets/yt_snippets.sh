#!/bin/bash
# ╭──────────────────────────────────────────────────────────────────────────────╮
# │                                                                              │
# │     Return the timestamps of the most popular parts of a youtube video       │
# │                                                                              │
# ╰──────────────────────────────────────────────────────────────────────────────╯

# Input
#


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
COOKIE_FILE="cookies.txt"
USERAGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 2 ]; then
        printf " ℹ️ Usage:\n $0 -v <YOUTUBE_VIDEO_ID> -n <NUMBER>\n\n" >&2 

        printf " Summary:\n"
        printf " Downloads the snippets of videos.\n\n"

        printf " Flags:\n"

        printf "  -v | --videoid <YOUTUBE_VIDEO_ID>\n"
        printf " \tSupply the youtube video ID to scan.\n\n"

        printf "  -c | --count <NUMBER>\n"
        printf " \tNumber of timestamps to return (most watched first).\n\n"

        printf "  -d | --duration <NUMBER>\n"
        printf " \tNumber of timestamps to return (most watched first).\n\n"

        printf "  -t | --timestamps <CSV_TIMESTAMPS>\n"
        printf " \tComma separated list of timestamps in seconds. no spaces.\n\n"

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

    BEST_VIDEO_URL=$(yt-dlp --cookies $COOKIE_FILE --get-url -f b "https://www.youtube.com/watch?v=$YOUTUBE_VIDEO_ID" --extractor-args "youtube:player-client=web,default;po_token=web+MnTDjl30_DR2RsO2J1t_PGkbRZtuuJ7eiVsc-FMqTAHKF1XqK6np9FDiO8hB8nAk4vd9Q7UFjc3YaZ6Zbbewi6wwYPL34lz7yiUiwPaypZEiaxtDy3YwjOcjy794g8LAA15tymrBlBgC5cWIS2eWa8U1PbZWlw==" --user-agent \"$USERAGENT\")

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


    # ╭───────────────────────────────────────────────────────╮
    # │       OVERRIDE with the custom set timestamps.        │
    # ╰───────────────────────────────────────────────────────╯
    if [ -n "$TIMESTAMPS" ]; then
        IFS=',' read -ra SECONDS_ARRAY <<< "$TIMESTAMPS"
        MOST_PLAYED_PARTS=""
        for seconds in "${SECONDS_ARRAY[@]}"; do
            milliseconds=$((seconds * 1000))
            MOST_PLAYED_PARTS+=("$milliseconds")
        done

        # echo ${MOST_PLAYED_PARTS[@]}
        return
    fi

    # ╭───────────────────────────────────────────────────────╮
    # │           If null, separate by 30 seconds.            │
    # ╰───────────────────────────────────────────────────────╯
    if [ "$MOST_REPLAYED" == "null" ]; then
        echo "--- No MOST_REPLAYED found - defaulting to 30sec increments from 0."
        MOST_PLAYED_PARTS=""
        for ((i = 0; i < COUNT; i++)); do
            value=$((i * 30000))
            MOST_PLAYED_PARTS+=("$value")
        done
        return
    fi


    # ╭───────────────────────────────────────────────────────╮
    # │    Read the JSON file and parse the top N highest      │
    # │    intensity scores with their startMillis values     │
    # ╰───────────────────────────────────────────────────────╯
    if [ "$MOST_REPLAYED" != "null" ]; then

        # We don't want to go over the end of the duration, so remove
        # any entries at the end that are within the duration period
        # 10secs = remove any of the entries that at 10secs from end
        REMOVED_END=$(echo "$MOST_REPLAYED" | jq -r --argjson DURATION_MILLISECONDS "$DURATION_MILLISECONDS" '.markers as $markers |  ($markers | map(.startMillis) | max) as $maxStartMillis | $markers | map(select(.startMillis < ($maxStartMillis - $DURATION_MILLISECONDS)))')

        # Sort by intensityScoreNormalized
        ALL_PLAYED_PARTS=$(echo "$REMOVED_END" | jq -r '. | sort_by(-.intensityScoreNormalized) | map(.startMillis | tostring) | .[]')

        # initialise arrays
        FILTERED_VALUES=()
        MOST_PLAYED_PARTS=()
        
        # convert ALL_PLAYED_PARTS to array 
        while IFS= read -r line; do
            FILTERED_VALUES+=("$line")
        done <<< "$ALL_PLAYED_PARTS"


        


        # Iterate through the values
        for ((i=0; i<${#FILTERED_VALUES[@]}; i++)); do
            # If it's the first value or the current value is >= DURATION away from the last added value
            CURRENT_VALUE=${FILTERED_VALUES[i]}

            # Add the first entry
            if [ $i -eq 0 ]; then
                MOST_PLAYED_PARTS+=("$CURRENT_VALUE")
            fi
            
            LESS_THAN_DURATION=false

            # is CURRENT_VALUE a minimum of 1000 (DURATION_MILLSECONDS) from
            # any entry in MOST_PLAYED_PARTS
            for element in "${MOST_PLAYED_PARTS[@]}"; do
                
                # Calculate the absolute difference between CURRENT_VALUE and 
                # each element in MOST_PLAYED_PARTS
                DIFFERENCE=$(( CURRENT_VALUE - element ))
                
                # If we find ANY matches, then skip it.
                if [ "$DIFFERENCE" -le "$DURATION_MILLISECONDS" ]; then
                    LESS_THAN_DURATION=true
                    break  # No need to check further if we find a match
                fi

            done

            # Current entry is not within DURATION of any other value.
            if ! $LESS_THAN_DURATION; then
                MOST_PLAYED_PARTS+=("$CURRENT_VALUE")
            fi
            
        done

        # Trim to $COUNT entries
        MOST_PLAYED_PARTS=("${MOST_PLAYED_PARTS[@]:0:$COUNT}")

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

    # LOOP through each entry
    for MILLISECONDS in "${MOST_PLAYED_PARTS[@]}"; do

        if [ "$MILLISECONDS" == "" ]; then continue; fi

        # Calculate start timestamp
        milliseconds_to_timestamp $MILLISECONDS
        START_TIMESTAMP=$RETURN_TIMESTAMP

        # Calculate end timestamp
        END_MILLISECONDS=$(($MILLISECONDS + $DURATION_MILLISECONDS))

        echo $END_MILLISECONDS

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