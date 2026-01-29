#!/bin/bash


# ==============================================================================
# SCRIPT: wifi-arg.sh (v10 - With Frequency)
# AUTHOR: Gemini
# DESCRIPTION: Scans for and lists available Wi-Fi networks using 'iw'.
#              Run as normal user. Uses sudo internally where needed.
#              Features:
#              - Explicit Interface Selection
#              - Intelligent Retry Loop for Scanning
#              - Robust Output Parsing (SSID, Freq, Channel, Signal, Security)
#              - Optional Regulatory Domain setting (--reg)
# REQUIREMENTS: iw, iproute2, sudo
# USAGE: ./wifi-arg.sh <interface> [--reg <COUNTRY_CODE>]
# EXAMPLE: ./wifi-arg.sh wlan0
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
if [[ -z "$1" ]]; then
    echo -e "${COLOR_ERROR}Error: No wireless interface specified.${COLOR_NONE}"
    echo "Usage: $0 <interface> <config_file>"
    echo "Example: ./wifi-connect.sh wlan1 wpa_supplicant.conf"
    echo ""
    echo "Available wireless interfaces:"
    iw dev | grep 'Interface' | awk '{print "  - " $2}' || echo "  (Could not find any)"
    exit 1
fi

INTERFACE="$1"
CONFIG="$2"

# Cleanup function to kill wpa_supplicant and dhcpcd
cleanup() {
    echo "Caught Ctrl+C! Killing wpa_supplicant and dhcpcd ..."
    sudo pkill -f "wpa_supplicant_s1g -D nl80211 -i $INTERFACE -c $CONFIG"
    sudo dhcpcd -r $INTERFACE
    sudo pkill -f "dhcpcd -i $INTERFACE"
    exit 1
}

# Trap SIGINT (Ctrl+C)
trap cleanup SIGINT

# Extract country code from config file (e.g., country=US)
COUNTRY=$(grep -E '^country=' "$CONFIG" | cut -d= -f2 | tr -d '"')

# Set regulatory domain if country was found
if [[ -n "$COUNTRY" ]]; then
    echo "Setting regulatory domain to $COUNTRY"
    sudo iw reg set "$COUNTRY"
else
    echo "No country code found in $CONFIG. Skipping iw reg set."
fi

# Extract ctrl_interface path from config(e.g., /var/run/wpa_supplicant/wlan1)
CTRL_PATH=$(grep -E '^ctrl_interface=' "$CONFIG" | cut -d= -f2 | tr -d '"')
CTRL_PATH=$CTRL_PATH/$INTERFACE

# Remove stale control interface directory/socket if it exists
if [[ -n "$CTRL_PATH" && -e "$CTRL_PATH" ]]; then
    echo "Removing existing ctrl_interface path: $CTRL_PATH"
    sudo rm -rf "$CTRL_PATH"
fi

# Start wpa_supplicant in the background
echo "Running wpa_supplicant"
sudo wpa_supplicant_s1g -D nl80211 -i "$INTERFACE" -c "$CONFIG" -B

# Give it some time to associate
sleep 5

# Release current lease
echo "Release current lease"
sudo dhcpcd -r $INTERFACE

# Start DHCP client
echo "Running dhcpcd on $INTERFACE interface"
sudo dhcpcd "$INTERFACE"

# Wait indefinitely or until interrupted
wait
