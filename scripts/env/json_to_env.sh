#!/bin/bash

cp config.json config_original.json

sed -i 's/\r\n/ /g' config.json

# Read and flatten JSON into environment variables
jq -r '
def to_env: gsub("[^a-zA-Z0-9]"; "_") | ascii_upcase;

# Recursive function to flatten nested objects and output as environment variables
def recurse_to_env($prefix; $obj):
  ($obj | to_entries) | .[] | (
    if (.value | type) == "object" then
      recurse_to_env("\($prefix)_\(.key | to_env)"; .value)
    else
      "\($prefix)_\(.key | to_env)=\(.value|tostring)"
    end
  );

# Start recursion from the root object
recurse_to_env("VC"; .)
' config_clean.json | while IFS= read -r line; do
  echo "$line"
  echo "$line" >> $GITHUB_ENV
done
