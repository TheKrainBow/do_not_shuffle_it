# do_not_shuffle_it

## How to use each files:

### .env
Edit this file to change json, log, and lock location. Every session must be able to access thoses files

### bash keyboard_tracking.sh

```nohup bash ./keyboard_tracking.sh &```

This will start keyboard_tracking.sh in background.  
It will automatically update keyboards.json if the computer using the script isn't already registered in it.

If the computer is already known, it will listen for USB connection/disconnection on the computer.  
If the school keyboard is unplugged, it will warn the user that it's forbidden.  
Any plug/unplug of a school keyboard will be logged on the LOG_FILE.  
If the session starts with the wrong keyboard, it will be logged as a mismatch.  
To avoid spamming logs, the session will temporarily accept the mismatched keyboard until the session is closed.  

### bash keyboard_search.sh

Since keyboards.json is used by multiple sessions at the same time, you should avoid accessing nor updating it while any session is running.  
If you need to search in the file, use ```bash ./keyboard_search <search_term>```.

It will search any match in the json, and display the result.

Omitting search_term will show you the whole keyboard.json data

### bash keyboard_migration.sh

This script will look at USB devices, and add a new entry to keyboard.json.
You don't need to use this script, it is already called by ```keyboard_tracking.sh``` when needed.
