#!/bin/bash

echo "Splitting database file per 50MB"

# Check if split files already exist
if ls tipitaka_pali_part.* 1> /dev/null 2>&1; then
    echo "Split files already exist. Exiting to prevent accidental deletion."
    exit 1
fi

# Split the file if it hasn't been split already
split -b 50000k tipitaka_pali.db tipitaka_pali_part.

# Delete the original file only if the split was successful
if [ $? -eq 0 ]; then
    echo "Deleting database file"
    rm tipitaka_pali.db
    echo "Success"
else
    echo "Error occurred during file split. Original file not deleted."
fi

