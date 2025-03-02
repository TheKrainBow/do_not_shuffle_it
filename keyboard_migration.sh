#!/bin/bash

# Shared JSON file location (ensure all PCs can access it)
JSON_FILE="./keyboards.json"

# Get computer name (modify this to match your setup)
COMPUTER_NAME=$(hostname)  # Or use a fixed name like "c1r1p1"

# Detect connected Keychron keyboard
KEYBOARD_INFO=$(lsusb | grep "Keychron" | awk '{print $0}' | sed 's/^.*ID/ID/')

# Ensure we found a keyboard
if [[ -z "$KEYBOARD_INFO" ]]; then
    echo "No keyboard detected."
    exit 1
fi

# Lock file to prevent simultaneous write issues
LOCK_FILE="./do_not_shuffle_it.lock"
exec 200>$LOCK_FILE
flock -x 200

# Update JSON file (append or modify entry)
if [[ -f "$JSON_FILE" ]]; then
    # Modify existing entry or add a new one
    jq --arg pc "$COMPUTER_NAME" --arg kb "$KEYBOARD_INFO" \
       '.[$pc] = $kb' "$JSON_FILE" > /tmp/keyboards_tmp.json && mv /tmp/keyboards_tmp.json "$JSON_FILE"
else
    # Create new JSON file
    echo "{" > "$JSON_FILE"
    echo "  \"$COMPUTER_NAME\": \"$KEYBOARD_INFO\"" >> "$JSON_FILE"
    echo "}" >> "$JSON_FILE"
fi

# Release lock
flock -u 200
exec 200>&-
