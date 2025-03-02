#!/bin/bash

# Source file with variables
source .env

COMPUTER_NAME=$(hostname)


## Utils

get_device_from_json() {
    DEVICE=$(jq -r --arg pc "$COMPUTER_NAME" '.[$pc]' "$JSON_FILE" 2> /dev/null)
}

show_warning_window() {
    zenity --error --title="Keyboard Disconnected" --text="We see you $USER..\nYou know that unplugging a keyboard is forbidden, right?" --width=400 --height=100 &
}

log_device_action() {
    local action="$1"

    # Get current timestamp in the format: YYYY-MM-DD HH:MM:SS
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to the file with the timestamp, action, and device name
    exec 200>$LOCK_FILE
    flock -x 200
    echo "$timestamp - $COMPUTER_NAME:$USER $action $DEVICE " >> "$LOG_FILE"
    flock -u 200
    exec 200>&-
}

check_device() {
    local device_name="$1"
    local var_name="$2"
    local -n device_status="$var_name"

    if lsusb | grep -q "$device_name"; then
        if ! $device_status; then
            device_status=true
            log_device_action "reconnected"
        fi
    elif $device_status; then
        device_status=false
        log_device_action "disconnected"
        show_warning_window
    fi
}


## Script

get_device_from_json
if [[ -z "$DEVICE" || "$DEVICE" == "null" ]]; then
    bash keyboard_migration.sh  # Call the migration script to add the device
    get_device_from_json
fi

if [[ -z "$DEVICE" || "$DEVICE" == "null"  ]]; then
    echo "Migration failed. Exiting."
    exit 1
fi

CURRENT_DEVICE=$(lsusb | grep "Keychron" | awk '{print $0}' | sed 's/^.*ID/ID/')
if [[ "$DEVICE" != "$CURRENT_DEVICE" ]]; then # Device found in json mismatch the connected one
    log_device_action "missmatch: $CURRENT_DEVICE != "
    DEVICE=$CURRENT_DEVICE
fi

device_connected=true

check_device "$DEVICE" device_connected

# Monitor loop
udevadm monitor --subsystem-match=usb --property | while read -r line; do
    if echo "$line" | grep -q "ACTION=remove" || echo "$line" | grep -q "ACTION=add"; then
        sleep 1
        check_device "$DEVICE" device_connected
    fi
done
