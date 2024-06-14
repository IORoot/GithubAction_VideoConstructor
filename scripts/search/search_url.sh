#!/bin/bash

# Check if a QUERY is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <QUERY>"
  exit 1
fi

# Store the QUERY
QUERY="$1"
LIMIT="${2:-3}"

# Temporary file to store search results
TEMP_FILE="raw.json"
URL_FILE="videoid_results.json"

# Search YouTube for the QUERY and get the details of the 10 newest results
yt-dlp --get-id --playlist-end $LIMIT "$QUERY"  > "$TEMP_FILE"

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

# Output the final JSON
cat "$URL_FILE"

# Remove the temporary files
rm "$TEMP_FILE"
