#!/bin/bash

# Check if a keyword is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <KEYWORD> <LIMIT> <FILTER>"
  exit 1
fi

# Store the keyword
KEYWORD="$1"
LIMIT="${2:-3}"

# Temporary file to store search results
TEMP_FILE="raw.json"
URL_FILE="videoid_results.json"

# Search YouTube for the keyword


if [ -n "$3" ]; then
  yt-dlp --flat-playlist -j "ytsearchdate$LIMIT:$KEYWORD" --match-filter "$3"  > "$TEMP_FILE"
else
  yt-dlp --flat-playlist -j "ytsearchdate$LIMIT:$KEYWORD" > "$TEMP_FILE"
fi

# Prepare the JSON structure
echo '{"results":[' > "$URL_FILE"

# Process each video ID to get the best-quality download URL
FIRST=1
while IFS= read -r line; do

  VIDEO_ID=$(echo "$line" | jq -r '.id')
  VIDEO_URL="https://www.youtube.com/watch?v=$VIDEO_ID"

  if [ $FIRST -eq 0 ]; then
    echo ',' >> "$URL_FILE"
  fi

  echo '{"video":"'"$VIDEO_URL"'"}' >> "$URL_FILE"
  FIRST=0
done < "$TEMP_FILE"

# Close the JSON structure
echo ']}' >> "$URL_FILE"

# Output the final JSON
cat "$URL_FILE"

# Remove the temporary files
rm "$TEMP_FILE"
