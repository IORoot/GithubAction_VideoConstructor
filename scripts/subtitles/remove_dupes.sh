#!/bin/bash


input_file="$1"
output_file="dedupe_${input_file}"

# Check if input file is provided
if [ -z "$input_file" ]; then
    echo "Usage: $0 <input_srt_file>"
    exit 1
fi

printf "Removing Duplicate Lines in %s\n" ${input_file}

temp_file=$(mktemp)

# Remove duplicate lines
awk '!seen[$1]++' $input_file > $temp_file

# Add newlines above each block
awk '/^[0-9]+$/{print ""} 1' $temp_file > $output_file 

rm "$temp_file"

echo "Deduplication complete. Output saved to $output_file"