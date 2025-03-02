#!/bin/bash

source .env

# Get the search parameter (Computer ID, Keyboard ID, or Keyboard Name)
SEARCH_PARAM="$1"

MATCHES_COUNT=0
# Function to search for a computer ID in the JSON file and display the relevant information
search_and_display() {
    local search_term="$1"

    # Find all matching computer IDs in the JSON file
    KEY_MATCHES=$(jq -r --arg term "$search_term" 'to_entries | map(select(.key | test($term))) | .[] | .key' "$JSON_FILE")
    VALUE_MATCHES=$(jq -r --arg term "$search_term" 'to_entries | map(select(.value | test($term))) | .[] | .key' "$JSON_FILE")


    if [[ -z "$KEY_MATCHES" && -z "$VALUE_MATCHES" ]]; then
        echo "No matching results found for '$search_term'."
        return
    fi

    # Combine both key and value matches into one string, remove duplicates, and loop through the results
    ALL_MATCHES=$(echo -e "$KEY_MATCHES\n$VALUE_MATCHES" | sort | uniq)


    if [[ -n "$search_term" ]]; then
        echo "Matching results for '$search_term':"
    fi
    echo "----------------------------"
    # Loop through all matches and display information
    while IFS= read -r COMPUTER_NAME; do
        # For each match, extract the keyboard info
        KEYBOARD_ID=$(jq -r --arg pc "$COMPUTER_NAME" '.[$pc]' "$JSON_FILE" | awk '{print $1, $2}')
        KEYBOARD_NAME=$(jq -r --arg pc "$COMPUTER_NAME" '.[$pc]' "$JSON_FILE" | awk '{print $3, substr($0, index($0, $3))}')

        # Skip if empty data
        if [[ -z "$COMPUTER_NAME" || "$COMPUTER_NAME" == "null" ]]; then
            continue
        fi
        ((MATCHES_COUNT++))
        # Display the found information
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

exec 200>$LOCK_FILE
flock -x 200

search_and_display "$SEARCH_PARAM"

flock -u 200
exec 200>&-
