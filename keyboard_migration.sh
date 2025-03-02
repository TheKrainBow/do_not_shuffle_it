#!/bin/bash

source .env

COMPUTER_NAME=$(hostname)

KEYBOARD_INFO=$(lsusb | grep "Keychron" | awk '{print $0}' | sed 's/^.*ID/ID/')

if [[ -z "$KEYBOARD_INFO" ]]; then
    echo "No keyboard detected."
    exit 1
fi

exec 200>$LOCK_FILE
flock -x 200

if [[ -f "$JSON_FILE" ]]; then
    # Modify existing entry or add a new one
    jq --arg pc "$COMPUTER_NAME" --arg kb "$KEYBOARD_INFO" \
       '.[$pc] = $kb' "$JSON_FILE" > /tmp/keyboards_tmp.json && mv /tmp/keyboards_tmp.json "$JSON_FILE"
else
    echo "{" > "$JSON_FILE"
    echo "  \"$COMPUTER_NAME\": \"$KEYBOARD_INFO\"" >> "$JSON_FILE"
    echo "}" >> "$JSON_FILE"
fi

flock -u 200
exec 200>&-
