#!/bin/bash



# # Read and flatten JSON into environment variables
# jq -r '
# def to_env: gsub("[^a-zA-Z0-9]"; "_") | ascii_upcase;

# # Recursive function to flatten nested objects and output as environment variables
# def recurse_to_env($prefix; $obj):
#   ($obj | to_entries) | .[] | (
#     if (.value | type) == "object" then
#       recurse_to_env("\($prefix)_\(.key | to_env)"; .value)
#     else
#       "\($prefix)_\(.key | to_env)=\(.value|tostring)"
#     end
#   );

# # Start recursion from the root object
# recurse_to_env("VC"; .)
# ' config.json | while IFS= read -r line; do
#   echo "$line"
#   echo "$line" >> $GITHUB_ENV
# done


# Read and flatten JSON into environment variables
jq -r '
def to_env: gsub("[^a-zA-Z0-9]"; "_") | ascii_upcase;

# Function to escape newlines
def escape_newlines:
  gsub("\r\n"; "__NEWLINE__") | gsub("\n"; "__NEWLINE__") | gsub("\r"; "__NEWLINE__");

# Recursive function to flatten nested objects and output as environment variables
def recurse_to_env($prefix; $obj):
  ($obj | to_entries) | .[] | (
    if (.value | type) == "object" then
      recurse_to_env("\($prefix)_\(.key | to_env)"; .value)
    else
      "\($prefix)_\(.key | to_env)=\(.value | tostring | escape_newlines)"
    end
  );

# Start recursion from the root object
recurse_to_env("VC"; .)
' config.json | while IFS= read -r line; do
  echo "$line"
  echo "$line" >> $GITHUB_ENV
done

