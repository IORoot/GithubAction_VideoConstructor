#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/generate"
PWD=$(pwd)


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

# ╭───────────────────────────────────────────────────────╮
# │     Loop through JSON and run midjourney on each      │
# ╰───────────────────────────────────────────────────────╯
function run_midjourney()
{
    JSON_CONTENT=$(cat "$JSON")
    JSON_KEYS=$(echo "$JSON_CONTENT" | jq -r 'keys[]')

    # Iterate through each top-level key in the JSON
    for section in $JSON_KEYS; do

        # Remove digits from the end of the section name to get the script name
        base_section_name=$(echo "$section" | grep -o '^[a-zA-Z_-]*')
        # script_name="output_${base_section_name}.sh"

        # Extract the run value
        run=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].run')
        prompt=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].prompt')
        upscale=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].upscale')

        printf "🏞️ %-10s : %s\n" "Prompt" "${prompt}"

        # Proceed only if run is true
        if [ "$run" == true ]; then
            npx tsx imagine.ts "${prompt}" "${upscale}"
        fi
        
    done
}


# ╭───────────────────────────────────────────────────────╮
# │     Download all images from the output TXT files      │
# ╰───────────────────────────────────────────────────────╯
function download_images()
{
    # Input file containing URLs
    INPUT_FILE="$1"

    # Check if input file exists
    if [ ! -f "$INPUT_FILE" ]; then
        echo "File not found: $INPUT_FILE"
        exit 0
    fi

    # Get name of TXT file and remove extension
    FILENAME_NO_EXTENSION="${INPUT_FILE%.*}"

    if [[ $FILENAME_NO_EXTENSION == *"quad"* ]]; then
        TYPE="quad"
    elif [[ $FILENAME_NO_EXTENSION == *"upscaled"* ]]; then
        TYPE="upscaled"
    else
        TYPE="none"
    fi

    # Read each line (URL) from the input file
    while IFS= read -r URL; do

        # Extract the part of the URL after the last slash and before the first question mark
        FILENAME=$(basename "$URL" | awk -F '?' '{print $1}')
        
        # Remove the suffix to get the descriptive part
        DESCRIPTIVE_PART=$(echo "$FILENAME" | sed -E 's/[_-][[:alnum:]]{8}-[[:alnum:]]{4}-[[:alnum:]]{4}-[[:alnum:]]{4}-[[:alnum:]]{12}\.png//')

        # Get new timestamp
        TIMESTAMP=$(date +%s)

        # Format the output filename with sequential suffix
        OUTPUT_FILE=$(printf "mj_%s_%s_%s.png" "$TYPE" "$DESCRIPTIVE_PART" "$TIMESTAMP")
        
        # Download the image using curl
        curl -# -o "$OUTPUT_FILE" "$URL"

    done < "$INPUT_FILE"
}

# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks

    run_midjourney

    download_images "midjourney_images_quad_urls.txt"
    download_images "midjourney_images_upscaled_urls.txt"

}

usage "$@"
arguments "$@"
main "$@"