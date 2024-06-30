#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
PWD=$(pwd)
UPLOADS_FOLDER="./uploads"
FOLDER_PREFIX="videoconstructor"
OUTPUT_FILELIST="./output_filelist.txt"
TYPE="SSHUNKNOWN"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will upload files to a server.\n\n"

        printf "Flags:\n"

        printf " --json <FILE>\n"
        printf "\tThe JSON file to read.\n\n"

        printf " --sshuser <SSHUSER>\n"
        printf "\tThe Username to use when uploading to a server.\n\n"

        printf " --sshpass <SSHPASS>\n"
        printf "\tThe Password to use when uploading to a server.\n\n"

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


        --sshuser)
            SSHUSER="$2"
            shift
            shift
            ;;


        --sshpass)
            SSHPASS="$2"
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
    if [ -z ${SSHUSER+x} ]; then
        printf "No SSHUSER user specified.\n"
        exit 1
    fi    

    if [ -z ${SSHPASS+x} ]; then
        printf "No SSHPASS password specified.\n"
        exit 1
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

    # Get the variables to upload onto server
    SERVER=$(cat $JSON | jq -r -c '.server')
    FOLDER=$(cat $JSON | jq -r -c '.folder')

    # Get current date for folder creation
    CURRENT_DATE=$(date +"%Y%m%d_%H%M%S")

    # Create a target folder name
    TARGET_DIR="${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE}/"

    # Get the SSH Fingerprint / public key for server
    mkdir -p ~/.ssh
    ssh-keyscan -H $SERVER >> ~/.ssh/known_hosts
   
    # SSH - Create a new folder on the server
    sshpass -p $SSHPASS ssh -v -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SSHUSER@$SERVER "mkdir -p ${TARGET_DIR}"

    # SCP - Copy all contents of uploads folder to server
    sshpass -p $SSHPASS scp -v -p -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./${UPLOADS_FOLDER}/* $SSHUSER@$SERVER:${TARGET_DIR}

    # Send to output_filelist.txt
    for file in $UPLOADS_FOLDER/*; do
        if [ ! -f "$file" ]; then
            continue
        fi
        
        if file -b --mime "$file" | grep -q "video"; then
            TYPE="SSHVIDEO"
        fi

        if file -b --mime "$file" | grep -q "image"; then
            TYPE="SSHIMAGE"
        fi

        MODIFIED_FOLDER="${FOLDER/\/var\/www\/vhosts\//}"
        echo "$TYPE:${MODIFIED_FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE}/$(basename "$file")" >> $OUTPUT_FILELIST

        TYPE="SSHUNKNOWN"
    done

    # Print output
    printf "📬 %-10s : %s\n" "SSH" "${TARGET_DIR}"
}

usage "$@"
arguments "$@"
main "$@"
