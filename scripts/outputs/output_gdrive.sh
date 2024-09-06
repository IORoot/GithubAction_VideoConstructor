#!/bin/bash
if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
PWD=$(pwd)
UPLOADS_FOLDER="./uploads"
FOLDER_PREFIX="videoconstructor"
OUTPUT_FILELIST="./output_filelist.txt"
MAX_RETRIES=3  # Maximum number of retries
RETRY_DELAY=60 # Delay in seconds between retries

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 --json [data.json]\n\n" >&2 

        printf "Summary:\n"
        printf "This will upload files to a google drive.\n\n"

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


# Upload to Google Drive with retry logic
function upload_to_gdrive() {

    printf "upload_to_gdrive()\n"

    local attempt=1
    local success=0
    while [[ $attempt -le $MAX_RETRIES ]]; do
        # Copy everything in uploads folder to Google Drive
        printf "rclone attempt\n"
        rclone copy $UPLOADS_FOLDER GDrive:${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE} --retries 5 --low-level-retries 10 --retries-sleep 5s --config $RCLONE_CONFIG 

        # Check the exit status
        if [[ $? -eq 0 ]]; then
            success=1
            break
        else
            echo "Attempt $attempt failed. Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
            ((attempt++))
        fi
    done

    if [[ $success -eq 0 ]]; then
        echo "Upload to Google Drive failed after $MAX_RETRIES attempts."
        return 1
    fi
    return 0
}



# Main function
function main() {

    printf "main()\n"

    pre_flight_checks

    # Get the folder to upload onto Google Drive
    FOLDER=$(cat $JSON | jq -r -c '.folder')

    # Get current date for folder creation
    CURRENT_DATE=$(date +"%Y%m%d_%H%M%S")

    # Try uploading to Google Drive
    if ! upload_to_gdrive; then
        exit 1  # Exit with error code to trigger the fallback in GitHub Actions
    else
        # Send to output_filelist.txt
        for file in $UPLOADS_FOLDER/*; do
            if [ -f "$file" ]; then
                echo "GDRIVE:${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE}/$(basename "$file")" >> $OUTPUT_FILELIST
            fi
        done

        printf "📬 %-10s : %s\n" "GDrive" "${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE}"
    fi
}




# # ╭──────────────────────────────────────────────────────────╮
# # │                                                          │
# # │                      Main Function                       │
# # │                                                          │
# # ╰──────────────────────────────────────────────────────────╯
# function main()
# {

#     pre_flight_checks

#     # Get the folder to upload onto google drive
#     FOLDER=$(cat $JSON | jq -r -c '.folder')

#     # Get current date for folder creation
#     CURRENT_DATE=$(date +"%Y%m%d_%H%M%S")

#     # Copy everything in uploads folder to google drive
#     rclone copy $UPLOADS_FOLDER GDrive:${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE} --retries 5 --low-level-retries 10 --retries-sleep 5s  --config $RCLONE_CONFIG 

#     # Send to output_filelist.txt
#     for file in $UPLOADS_FOLDER/*; do
#         if [ -f "$file" ]; then
#             echo "GDRIVE:${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE}/$(basename "$file")" >> $OUTPUT_FILELIST
#         fi
#     done

#     printf "📬 %-10s : %s\n" "GDrive" "${FOLDER}/${FOLDER_PREFIX}_${CURRENT_DATE}"
# }

usage "$@"
arguments "$@"
main "$@"
