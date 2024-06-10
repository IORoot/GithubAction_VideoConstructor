#!/bin/bash

# Check if a keyword is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <keyword>"
  exit 1
fi

# Store the keyword
KEYWORD="$1"
LIMIT="${2:-3}"

# Temporary file to store search results
TEMP_FILE="raw.json"
URL_FILE="results.json"

# Search YouTube for the keyword and get the details of the 10 newest results
yt-dlp --flat-playlist -j "ytsearchdate$LIMIT:$KEYWORD" > "$TEMP_FILE"

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

  # Adds the Download URL if needed.
  # DOWNLOAD_URL=$(yt-dlp -f b --get-url "$VIDEO_URL")
  # echo '{"video":"'"$VIDEO_URL"'","download":"'"$DOWNLOAD_URL"'"}' >> "$URL_FILE"
  
  echo '{"video":"'"$VIDEO_URL"'"}' >> "$URL_FILE"
  FIRST=0
done < "$TEMP_FILE"

# Close the JSON structure
echo ']}' >> "$URL_FILE"

# Output the final JSON
cat "$URL_FILE"

# Remove the temporary files
rm "$TEMP_FILE"
