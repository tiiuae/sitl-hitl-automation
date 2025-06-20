#!/bin/bash

# Usage: ./generate_px4_file_info.sh /path/to/firmware > output.json

FIRMWARE_DIR=$1

if [ -z "$FIRMWARE_DIR" ]; then
    echo "Usage: $0 /path/to/firmware-dir" >&2
    exit 1
fi

echo '{'
echo '  "files": ['

first=1
for file in "$FIRMWARE_DIR"/*.px4; do
    [ -e "$file" ] || continue  # skip if no .px4 files

    filename=$(basename "$file")
    filepath="$file"
    filepath=$(realpath "$filepath")
    # Extract hardware name from filename (assumes format: ssrc_<hw>.px4)
    hw=$(echo "$filename" | sed -E 's/^ssrc_([^_]+-[^-]+)-.*/\1/') 
    
    # Get the modification time (epoch)
    px4_build_time=$(stat -c %Y "$file")

    # Add comma if not the first entry
    if [ $first -eq 0 ]; then
        echo ','
    fi
    first=0

    cat <<EOF
    {
      "filename": "$filepath",
      "hw": "$hw",
      "px4_build_time": "$px4_build_time",
      "type": "px4-firmware"
    }
EOF

done

echo
echo '  ]'
echo '}'

