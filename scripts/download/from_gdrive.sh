#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/download"
PWD=$(pwd)
FILELIST="./download_from_server_filelist.txt"
COUNT=1

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will download public files from a server.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

        printf " --config <RCLONE.conf>\n"
        printf "\tThe RCLONE Config file to read.\n\n"

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


        --config)
            RCLONE_CONFIG="$2"
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

    if [ ! -f "$RCLONE_CONFIG" ]; then
        printf "No RCLONE_CONFIG config file found.\n"
        exit 1
    fi    

}

function read_config()
{
    FOLDER=$(cat $JSON | jq -r -c '.folder')
    COUNT=$(cat $JSON | jq -r -c '.count')
    STRATEGY=$(cat $JSON | jq -r -c '.strategy')

    if [ $STRATEGY == "picked" ]; then
        FILES=$(cat $JSON | jq -r -c '.files')
    fi
}



# ╭───────────────────────────────────────────────────────╮
# │               Download a Single File                  │
# ╰───────────────────────────────────────────────────────╯
function download_single_file()
{

    if [ "$COUNT" -gt 1 ]; then
        for i in $(seq 1 $COUNT); do

            OUTPUT_FILE=$(basename $FOLDER)
            OUTPUT_FILE_LOOPNAME="${i}_${OUTPUT_FILE}"

            # print to screen
            printf "📥 %-10s : %s\n" "Single" "$FOLDER"

            rclone copyto GDrive:$FOLDER ${OUTPUT_FILE_LOOPNAME}  --config ${RCLONE_CONFIG}

        done
    else
        OUTPUT_FILE=$(basename $FOLDER)
        printf "📥 %-10s : %s\n" "Single" "$FOLDER"
        rclone copy GDrive:$FOLDER ${OUTPUT_FILE}  --config ${RCLONE_CONFIG}
    fi
    
}



# ╭───────────────────────────────────────────────────────╮
# │               Download the newest files                │
# ╰───────────────────────────────────────────────────────╯
function download_files_with_strategy_newest()
{

    # Get a full list of all files in remote directory + MODIFICTAION TIMES
    FILELIST=$(rclone lsl --config $RCLONE_CONFIG GDrive:$FOLDER)

    # Check if FILELIST is not empty
    if [ -z "$FILELIST" ]; then
        echo "No files found in GDrive:$FOLDER"
        exit 1
    fi
    
    # Newest files
    SELECTED_FILES=$(echo "$FILELIST" | sort -rk2,2 | head -n "$COUNT" | while read -r line; do echo "${line##* }"; done)

    # Loop through the selected files and download each one
    for FILE in $SELECTED_FILES; do
        rclone copyto --config $RCLONE_CONFIG "GDrive:$FOLDER/$FILE" "./$FILE"
        printf "📥 %-10s : %s\n" "Newest" "GDrive:$FOLDER/$FILE"
    done
}


# ╭───────────────────────────────────────────────────────╮
# │               Download the Oldest files                │
# ╰───────────────────────────────────────────────────────╯
function download_files_with_strategy_oldest()
{

    # Get a full list of all files in remote directory + MODIFICTAION TIMES
    FILELIST=$(rclone lsl --config $RCLONE_CONFIG GDrive:$FOLDER)

    # Check if FILELIST is not empty
    if [ -z "$FILELIST" ]; then
        echo "No files found in GDrive:$FOLDER"
        exit 1
    fi
    
    # Oldest files
    SELECTED_FILES=$(echo "$FILELIST" | sort -rk2,2 | tail -n "$COUNT" | while read -r line; do echo "${line##* }"; done)

    # Loop through the selected files and download each one
    for FILE in $SELECTED_FILES; do
        rclone copyto --config $RCLONE_CONFIG "GDrive:$FOLDER/$FILE" "./$FILE"
        printf "📥 %-10s : %s\n" "Oldest" "GDrive:$FOLDER/$FILE"
    done
}


# ╭───────────────────────────────────────────────────────╮
# │        Download files with a RANDOM strategy           │
# ╰───────────────────────────────────────────────────────╯
function download_files_with_strategy_random()
{

    # Get a full list of all files in remote directory
    FILELIST=$(rclone lsf --config $RCLONE_CONFIG GDrive:$FOLDER)

    # Check if FILELIST is not empty
    if [ -z "$FILELIST" ]; then
        echo "No files found in GDrive:$FOLDER"
        exit 1
    fi
    
    # Pick random files
    SELECTED_FILES=$(echo "$FILELIST" | shuf -n $COUNT)

    # Loop through the selected files and download each one
    for FILE in $SELECTED_FILES; do
        rclone copyto --config $RCLONE_CONFIG "GDrive:$FOLDER/$FILE" "./$FILE"
        printf "📥 %-10s : %s\n" "Random" "GDrive:$FOLDER/$FILE"
    done
}


# ╭───────────────────────────────────────────────────────╮
# │         Download Specific Files from the list          │
# ╰───────────────────────────────────────────────────────╯
function download_specific_files()
{
    
    if [ ! -n $FILES ];then
        printf "No Specific File given. Exit."
        exit 1.
    fi

    cat $JSON | jq -r -c '.files[].file' | while read -r DOWNLOADFILE; do

        # print to screen
        printf "📥 %-10s : %s\n" "Specific" "$FOLDER/$DOWNLOADFILE"

        # download
        rclone copyto --config $RCLONE_CONFIG "GDrive:$FOLDER/$DOWNLOADFILE" "./$DOWNLOADFILE"

    done
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

    # If The source URL is a txt file with a filelist in it
    if [ $STRATEGY == "single" ]; then
        download_single_file
    fi

    if [[ $STRATEGY == "picked" ]]; then
        download_specific_files
    fi

    if [[ $STRATEGY == "newest" ]]; then
        download_files_with_strategy_newest
    fi 

    if [[ $STRATEGY == "oldest" ]]; then
        download_files_with_strategy_oldest
    fi 

    if [[ $STRATEGY == "random" ]]; then
        download_files_with_strategy_random
    fi 


}

usage "$@"
arguments "$@"
main "$@"
