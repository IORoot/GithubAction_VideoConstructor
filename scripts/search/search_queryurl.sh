#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
TEMP_FILE="raw.json"
URL_FILE="search_results_queryurl.json"; i=1; while [ -e "$URL_FILE" ]; do URL_FILE="search_results_queryurl${i}.json"; ((i++)); done
RESULTS_FILE="search_results.json"
COUNT="3"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 <QUERY> <LIMIT> <FILTER> \n\n" >&2 

        printf "Summary:\n"
        printf "This will search youtube using a queryurl.\n\n"

        printf "Flags:\n"

        printf " --queryurl <Query URL>\n"
        printf "\tTarget YouTube URL.\n\n"

        printf " --filter <YT-DLP FILTER>\n"
        printf "\tUse a YT-DLP Filter on results.\n\n"

        printf " --count <Count>\n"
        printf "\tNumber of results to return.\n\n"

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

        --queryurl)
            QUERY="$2"
            shift
            shift
            ;;


        --filter)
            FILTER="$2"
            shift
            shift
            ;;


        --count)
            COUNT="$2"
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


function do_search()
{

  # Search YouTube for the QUERY
  if [ -n "$FILTER" ]; then
    FILTER_PARAM="--match-filter ${FILTER}"
  fi

  echo yt-dlp --get-id --playlist-end $COUNT "$QUERY" $FILTER_PARAM
  yt-dlp --get-id --playlist-end $COUNT "$QUERY" $FILTER_PARAM > "$TEMP_FILE"
}


function output_results()
{

  # Prepare the JSON structure
  echo '{"results":[' > "$URL_FILE"

  # Process each video ID to get the best-quality download URL
  FIRST=1
  while IFS= read -r line; do

    VIDEO_URL="https://www.youtube.com/watch?v=$line"

    if [ $FIRST -eq 0 ]; then
      echo ',' >> "$URL_FILE"
    fi

    echo '{"video":"'"$VIDEO_URL"'"}' >> "$URL_FILE"
    FIRST=0
  done < "$TEMP_FILE"

  # Close the JSON structure
  echo ']}' >> "$URL_FILE"
}



function append_to_results_file()
{
  if [ ! -f "$URL_FILE" ]; then
    echo "New $URL_FILE file does not exist."
    exit 1
  fi

  NEW_RESULTS=$(cat "$URL_FILE")

  if [ -f "$RESULTS_FILE" ]; then
    EXISTING_RESULTS=$(cat "$RESULTS_FILE")
    COMBINED_RESULTS=$(echo "$EXISTING_RESULTS $NEW_RESULTS" | jq -s '.[0].results + .[1].results | {results: .}')
  else
    COMBINED_RESULTS="$NEW_RESULTS"
  fi

  echo "$COMBINED_RESULTS" > "$RESULTS_FILE"
}


function cleanup()
{
  # Remove the temporary files
  rm "$TEMP_FILE"
}



# ╭──────────────────────────────────────────────────────────╮
# │                                                          │
# │                      Main Function                       │
# │                                                          │
# ╰──────────────────────────────────────────────────────────╯
function main()
{

  do_search
  output_results
  append_to_results_file
  cleanup
  
  # Output the final JSON
  cat "$URL_FILE"
}

usage "$@"
arguments "$@"
main "$@"
