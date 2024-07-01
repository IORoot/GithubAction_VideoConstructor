#!/bin/bash

if [[ "${DEBUG-0}" == "1" ]]; then set -o xtrace; fi        # DEBUG=1 will show debugging.

# ╭──────────────────────────────────────────────────────────╮
# │                        VARIABLES                         │
# ╰──────────────────────────────────────────────────────────╯
TEMP_FILE="raw.json"
URL_FILE="search_results_keyword_in_channels.json"; i=1; while [ -e "$URL_FILE" ]; do URL_FILE="search_results_keyword_in_channels${i}.json"; ((i++)); done
RESULTS_FILE="search_results.json"
COUNT="3"
CHANNELSFILE="channels.txt"

# ╭──────────────────────────────────────────────────────────╮
# │                          Usage.                          │
# ╰──────────────────────────────────────────────────────────╯

usage()
{
    if [ "$#" -lt 1 ]; then
        printf "ℹ️ Usage:\n $0 <KEYWORDS> <LIMIT> <FILTER> \n\n" >&2 

        printf "Summary:\n"
        printf "This will search youtube using a keyword.\n\n"

        printf "Flags:\n"

        printf " --keyword <KEYWORDS>\n"
        printf "\tTarget YouTube KEYWORDS.\n\n"

        printf " --filter <YT-DLP FILTER>\n"
        printf "\tUse a YT-DLP Filter on results.\n\n"

        printf " --count <Count>\n"
        printf "\tNumber of results to return.\n\n"

        printf " --channelsfile <File>\n"
        printf "\tName of file with list of channels to search.\n\n"

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

        --keyword)
            KEYWORD="$2"
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


        --channelsfile)
            CHANNELSFILE="$2"
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

  if [ -n "$FILTER" ]; then
    FILTER_PARAM="--match-filter ${FILTER}"
  fi

  total_channels=$(wc -l < channels.txt)
  current_channel=0

  while IFS= read -r channel; do
      current_channel=$((current_channel + 1))
      echo "Processing channel $current_channel of $total_channels: $channel"

      # Construct the search URL for the channel
      search_url="${channel}/search?query=${KEYWORD}"

      echo $search_url

      # Get results
      yt-dlp --flat-playlist -J "$search_url" | jq -r --argjson limit "$COUNT" '[ limit($limit; .entries[] | {title: .title, id: .id, channel: .uploader} ) ]' > "$TEMP_FILE"

  done < "$CHANNELSFILE"

}



function output_results()
{
  jq -r '[.[] | {video: ("https://www.youtube.com/watch?v=" + .id)}] | {results: .}' $TEMP_FILE > $URL_FILE
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
  rm "$CHANNELSFILE"
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
  # cleanup
  
  
  # Output the final JSON
  cat "$URL_FILE"
}

usage "$@"
arguments "$@"
main "$@"
