#!/bin/bash

# ==============================================================================
# SCRIPT: wifi-stats.sh
# AUTHOR: Gemini
# DESCRIPTION: Print interface connection.
#              Run as normal user. Uses sudo internally where needed.
#              Features:
#              - Explicit Interface Selection
#              - Intelligent Retry Loop for Scanning
#              - Robust Output Parsing
# REQUIREMENTS: iw, iproute2, sudo
# USAGE: ./wifi-stats.sh <interface>
# EXAMPLE: ./wifi-stats.sh wlan0
# ==============================================================================

# --- Configuration ---
COLOR_HEADER=$'\033[1;34m' # Bold Blue
COLOR_ERROR=$'\033[1;31m'  # Bold Red
COLOR_NONE=$'\033[0m'     # No Color

SCAN_TIMEOUT=15
RETRY_INTERVAL=1

# --- Sanity Checks & Setup ---

SUDO_CMD=""
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${COLOR_ERROR}Error: 'sudo' command not found. Please run this script as root.${COLOR_NONE}"
        exit 1
    fi
    SUDO_CMD="sudo"
fi

# --- Check if an interface is provided ---
if [ -z "$1" ]; then
    echo -e "${COLOR_ERROR}Error: No wireless interface specified.${COLOR_NONE}"
    echo "Usage: $0 <interface_name>"
    echo ""
    echo "Available wireless interfaces:"
    iw dev | grep 'Interface' | awk '{print "  - " $2}' || echo "  (Could not find any)"
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
