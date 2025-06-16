#!/bin/bash

INPUT_DIR="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "Usage: $0 <input_dir> <output_file.json>"
  exit 1
fi

echo "[" > "$OUTPUT_FILE"
first=1

find "$INPUT_DIR" -type f -name "*.bin" | while read -r filepath; do
  filename=$(basename "$filepath")
  filepath=$(realpath "$filepath")

  # Match filenames like: ssrc_saluki-v2_custom_ssbl_bootloader-2.7.0.bin
  if [[ "$filename" =~ ^ssrc_(.+)_([a-zA-Z0-9]+)_bootloader.*\.bin$ ]]; then
    hw="${BASH_REMATCH[1]}"
    stage="${BASH_REMATCH[2]}"

    # Add comma if not the first entry
    if [ $first -eq 0 ]; then
      echo "," >> "$OUTPUT_FILE"
    fi
    first=0

    # Append the JSON object
    cat <<EOF >> "$OUTPUT_FILE"
{
  "filename": "$filepath",
  "hw": "$hw",
  "stage": "$stage",
  "type": "bootloader"
}
EOF
  fi
done

echo "]" >> "$OUTPUT_FILE"

