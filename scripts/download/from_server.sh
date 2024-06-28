#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
FOLDER="./scripts/download"
PWD=$(pwd)
FILELIST="./download_from_server_filelist.txt"
COUNT=1
TMPFILE="./download_from_server_picked.txt"

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
        printf "No JSON config file found.\n"
        exit 1
    fi    

}

function read_config()
{
    SOURCEURL=$(cat $JSON | jq -r -c '.sourceurl')
    COUNT=$(cat $JSON | jq -r -c '.count')
    STRATEGY=$(cat $JSON | jq -r -c '.strategy')

    if [ $STRATEGY == "picked" ]; then
        FILES=$(cat $JSON | jq -r -c '.files')
    fi
}

function download_txtfile()
{
    # Check if a url source has been set.
    if [ -z ${SOURCEURL+x} ]; then 
        printf "No Source URL given."
        return 0; 
    fi

    if [[ "$SOURCEURL" != *.txt ]]; then 
        printf "Source URL is not a TXT file. Must provide txt file with list of all files in it."
        return 0; 
    fi

    # download the txt file with list of files
    curl --insecure --silent --show-error --url "$SOURCEURL" --output ${FILELIST} 2>/dev/null

    # Check if file exists.
    if [ ! -f ${FILELIST} ]; then return 0; fi
    
}


# ╭───────────────────────────────────────────────────────╮
# │               Download a Single File                  │
# ╰───────────────────────────────────────────────────────╯
function download_single_file()
{

    if [ "$COUNT" -gt 1 ]; then
        for i in $(seq 1 $COUNT); do
            OUTPUT_FILE=$(basename $SOURCEURL)
            OUTPUT_FILE_LOOPNAME="${i}_${OUTPUT_FILE}"

            # print to screen
            printf "📥 %-10s : %s\n" "Single" "$SOURCEURL"

            curl --insecure --silent --show-error --url "$SOURCEURL" --output ${OUTPUT_FILE_LOOPNAME} 2>/dev/null
        done
    else
        OUTPUT_FILE=$(basename $SOURCEURL)
        printf "📥 %-10s : %s\n" "Single" "$SOURCEURL"
        curl --insecure --silent --show-error --url "$SOURCEURL" --output ${OUTPUT_FILE} 2>/dev/null
    fi
    
}


# ╭───────────────────────────────────────────────────────╮
# │            Download files with a strategy              │
# ╰───────────────────────────────────────────────────────╯
function download_files_with_strategy()
{

    LOOP=1
    while read FILE; do

        # Filename
        OUTPUT_FILE=${LOOP}_${FILE}
        DIRPATH="${SOURCEURL%/*}"

        # print to screen
        printf "📥 %-10s : %s\n" "$STRATEGY" "$DIRPATH/$FILE"

        # download
        curl --insecure --silent --show-error --url "$DIRPATH/$FILE" --output ${OUTPUT_FILE} 2>/dev/null

        # Iterate.
        LOOP=$(( $LOOP + 1 ))

    done < ${TMPFILE}
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

        # remove filelist.txt at end
        DIRPATH="${SOURCEURL%/*}"

        # print to screen
        printf "📥 %-10s : %s\n" "Specific" "$DIRPATH/$DOWNLOADFILE"

        # download
        curl --insecure --silent --show-error --url "$DIRPATH/$DOWNLOADFILE" --output ${DOWNLOADFILE} 2>/dev/null

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
        download_txtfile
        cat ${FILELIST} | head -n "$COUNT" > ${TMPFILE}
        download_files_with_strategy
    fi 

    if [[ $STRATEGY == "oldest" ]]; then
        download_txtfile
        cat ${FILELIST} | tail -n "$COUNT" > ${TMPFILE}
        download_files_with_strategy
    fi 

    if [[ $STRATEGY == "random" ]]; then
        download_txtfile
        cat ${FILELIST} | sort -R | head -n "$COUNT" > ${TMPFILE}
        download_files_with_strategy
    fi 


}

usage "$@"
arguments "$@"
main "$@"
