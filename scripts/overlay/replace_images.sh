#!/bin/bash

# This script looks into the overlay assets folder and replaces any images that have
# URLs and rewrites them to be local images. So:
#
# "src":"\/\/localhost:8100\/wp-content\/uploads\/revslider\/svg\/objects\/svgcustom\/LondonParkour_wide.svg"
#
# becomes:
#
# "src":"./assets/LondonParkour_wide.svg"


# Check if the directory argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Directory to search for JSON files
search_dir="$1"

# Check if the directory exists
if [ ! -d "$search_dir" ]; then
    echo "Directory $search_dir does not exist. Skipping"
    exit 0
fi

# Process all JSON files in the specified directory
for input_file in "$search_dir"/*.json; do
    # Check if any JSON files are found
    if [[ -e "$input_file" ]]; then
        # Use sed to replace the src locations and overwrite the file
        sed -E 's#("src":")[^"]*/([^"]*)"#\1./assets/\2"#g' "$input_file" > "$input_file.tmp" && mv "$input_file.tmp" "$input_file"
        
        echo "Updated $input_file"
    else
        echo "No JSON files found in $search_dir."
    fi
done
