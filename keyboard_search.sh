#!/bin/bash

source .env

SEARCH_PARAM="$1"
MATCHES_COUNT=0


## Utils

search_and_display() {
    local search_term="$1"

    KEY_MATCHES=$(jq -r --arg term "$search_term" 'to_entries | map(select(.key | test($term))) | .[] | .key' "$JSON_FILE")
    VALUE_MATCHES=$(jq -r --arg term "$search_term" 'to_entries | map(select(.value | test($term))) | .[] | .key' "$JSON_FILE")
    if [[ -z "$KEY_MATCHES" && -z "$VALUE_MATCHES" ]]; then
        echo "No matching results found for '$search_term'."
        return
    fi

    ALL_MATCHES=$(echo -e "$KEY_MATCHES\n$VALUE_MATCHES" | sort | uniq)

    echo "----------------------------"
    while IFS= read -r COMPUTER_NAME; do
        KEYBOARD_ID=$(jq -r --arg pc "$COMPUTER_NAME" '.[$pc]' "$JSON_FILE" | awk '{print $1, $2}')
        KEYBOARD_NAME=$(jq -r --arg pc "$COMPUTER_NAME" '.[$pc]' "$JSON_FILE" | awk '{print $3, substr($0, index($0, $3))}')

        # Skip if empty data
        if [[ -z "$COMPUTER_NAME" || "$COMPUTER_NAME" == "null" ]]; then
            continue
        fi
        ((MATCHES_COUNT++))
        echo "ComputerName: $COMPUTER_NAME"
        echo "Keyboard ID: $KEYBOARD_ID"
        echo "Keyboard Name: $KEYBOARD_NAME"
        echo "----------------------------"
    done <<< "$ALL_MATCHES"

    if [[ -n "$search_term" ]]; then
        echo
        ENTRY_COUNT=$(jq 'length' "$JSON_FILE")
        echo "$MATCHES_COUNT entries found on $ENTRY_COUNT total with search term '$search_term'"
    fi
}


## Script

exec 200>$LOCK_FILE
flock -x 200

search_and_display "$SEARCH_PARAM"

flock -u 200
exec 200>&-
