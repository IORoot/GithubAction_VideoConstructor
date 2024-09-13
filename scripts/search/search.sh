#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/search"
COOKIE_FILE="cookies.txt"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json] \n\n" >&2 

        printf "Summary:\n"
        printf "This will switch the search to the correct script.\n\n"

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
        printf "No file found."
    fi

}


execute_script() {
    local script_name="$1"
    shift  # Shifts the arguments to skip the script_name
    local args=("$@")  # Store remaining arguments in an array

    # Execute the script with the arguments
    echo "Executing: bash \"$script_name\" ${args[*]}"
    bash "$script_name" "${args[@]}"
}

# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │              Execute the correct script               │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
run_script() {

    local section_name=$1
    local section_content=$2

    # Extract the run value
    run=$(echo "$section_content" | jq -r '.run')

    # Proceed only if run is true
    if [ "$run" == "true" ]; then

        # Remove digits from the end of the section name to get the script name
        base_section_name=$(echo "$section_name" | grep -o '^[a-zA-Z_-]*')
        script_name="search_${base_section_name}.sh"

        # Prepare an array to hold parameters
        local args=()

        # Add each key-value pair as an argument to the array
        while IFS= read -r key; do

            # get value
            value=$(echo "$section_content" | jq -r --arg key "$key" ".$key")

            # remove spaces
            value=${value// /}

            # Don't apply any flags with no value.
            if [ ! -z "$value" ]; then
                args+=("--$key" "$value")
            fi

        done < <(echo "$section_content" | jq -r 'del(.run) | keys[]')

        # Add cookies flag
        args+=("--cookies" "$COOKIE_FILE")

        # Execute the script with the prepared arguments
        execute_script "$FOLDER/$script_name" "${args[@]}"
    fi

}

# ╭───────────────────────────────────────────────────────╮
# │                                                       │
# │             Replace channels with a file               │
# │                                                       │
# ╰───────────────────────────────────────────────────────╯
function handle_channels()
{
    channels_section=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section].channels')
    channels=$(echo "$channels_section" | jq -r '.[].channel')

    # Write the extracted channels to channels.txt with newline at the end of each entry
    while IFS= read -r channel; do
        printf "%s\n" "$channel" >> channels.txt
    done <<< "$channels"

    # Replace 
    # Use jq to update the specific section based on $section variable
    updated_json=$(echo "$JSON_CONTENT" | jq --arg section "$section" '
        if .[$section] then
            .[$section] |= del(.channels) | .[$section] |= . + { "channelsfile": "channels.txt" }
        else
            .
        end
    ')

    JSON_CONTENT=$updated_json
}


# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

    pre_flight_checks

    JSON_CONTENT=$(cat "$JSON")

    # Iterate through each top-level key in the JSON
    for section in $(echo "$JSON_CONTENT" | jq -r 'keys[]'); do
        
        section_content=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section]')

        # Remove any numbers from the end.
        base_section_name=$(echo "$section" | grep -o '^[a-zA-Z_-]*')

        run=$(echo "$section_content" | jq -r '.run')

        # Special Case for keyword_in_channels
        if [[ $base_section_name == 'keyword_in_channels' && $run = "true" ]]; then
            handle_channels
            section_content=$(echo "$JSON_CONTENT" | jq -r --arg section "$section" '.[$section]')
        fi

        run_script "$section" "$section_content"
    done

}

usage "$@"
arguments "$@"
main "$@"