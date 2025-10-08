#!/bin/bash

# Check if an interface is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <wireless_interface>"
    echo "Example: $0 wlan0"
    exit 1
fi

INTERFACE=$1

# Verify if the interface exists
if ! iw dev | grep -q "$INTERFACE"; then
    echo "Error: Interface $INTERFACE not found or not a wireless interface."
    exit 1
fi

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\nStopped by user."; exit 0' SIGINT

# Run in a loop until interrupted
while true; do
    # Clear the screen for cleaner output
    clear

    # Get iw station dump output
    STATION_DUMP=$(iw dev "$INTERFACE" station dump 2>/dev/null)

    # Check if station dump is empty (no connected stations)
    if [ -z "$STATION_DUMP" ]; then
        echo "No stations connected to $INTERFACE."
    else
        # Extract signal and bitrate
        SIGNAL=$(echo "$STATION_DUMP" | grep "signal avg" | awk '{print $3}' | head -n 1)
        BITRATE=$(echo "$STATION_DUMP" | grep "tx bitrate" | awk '{print $3 " " $4}' | head -n 1)

        # Handle cases where signal or bitrate might not be available
        if [ -z "$SIGNAL" ]; then
            SIGNAL="N/A"
        else
            SIGNAL="$SIGNAL dBm"
        fi

        if [ -z "$BITRATE" ]; then
            BITRATE="N/A"
        fi

        # Pretty print output
        echo "=================================="
        echo "Wireless Interface: $INTERFACE"
        echo "----------------------------------"
        echo "Signal Strength (Avg): $SIGNAL"
        echo "Bitrate: $BITRATE"
        echo "=================================="
        echo "Press Ctrl+C to stop."
    fi

    # Wait for 2 seconds before the next update
    sleep 2
done
