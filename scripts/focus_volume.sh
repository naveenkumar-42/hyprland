#!/bin/bash

LOGFILE="/tmp/focus_volume.log"
echo "$(date): Running focus volume script" >> "$LOGFILE"

# Get active window class
ACTIVE_APP=$(/usr/bin/hyprctl activewindow -j | /usr/bin/jq -r '.class')
echo "$(date): Active window: $ACTIVE_APP" >> "$LOGFILE"

# Media applications to control
MEDIA_APPS=("spotify" "vlc" "mpv" "firefox" "chromium" "brave")

# Loop through media apps
for APP in "${MEDIA_APPS[@]}"; do
    # Extract all active sink input IDs for the app
    SINK_INPUTS=$(/usr/bin/pactl list sink-inputs | awk -v app="$APP" '
        /Sink Input #/ {sink=$3+0;}  # Convert to number, removes '#'
        /application.process.binary/ && $3 ~ app {print sink;}
    ')

    # Skip if no sink input found
    if [[ -z "$SINK_INPUTS" ]]; then
        echo "$(date): No valid sink found for $APP" >> "$LOGFILE"
        continue
    fi

    # Process multiple sinks if they exist
    for SINK in $SINK_INPUTS; do
        if [[ "$ACTIVE_APP" == "$APP" ]]; then
            /usr/bin/pactl set-sink-input-volume "$SINK" 100%
            echo "$(date): Set volume to 100% for $APP (Sink #$SINK)" >> "$LOGFILE"
        else
            /usr/bin/pactl set-sink-input-volume "$SINK" 50%
            echo "$(date): Reduced volume to 50% for $APP (Sink #$SINK)" >> "$LOGFILE"
        fi
    done
done
