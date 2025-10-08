#!/bin/bash

# ==============================================================================
# SCRIPT: list_wifi_arg.sh (v7 - Robust Quoting)
# AUTHOR: Gemini
# DESCRIPTION: Scans for and lists available Wi-Fi networks using 'iw'.
#              Fixes a shell quoting issue by using C-style string assignments
#              for color variables, preventing parsing errors.
# REQUIREMENTS: iw, iproute2 (for the 'ip' command)
# USAGE: sudo ./list_wifi_arg.sh <interface>
# EXAMPLE: sudo ./list_wifi_arg.sh wlan0
# ==============================================================================

# --- Configuration ---
# CORRECTED: Using C-style strings ($'...') is a more robust way to define
# variables containing escape codes and avoids shell quoting errors.
COLOR_HEADER=$'\033[1;34m' # Bold Blue
COLOR_ERROR=$'\033[1;31m'  # Bold Red
COLOR_NONE=$'\033[0m'     # No Color

SCAN_TIMEOUT=15
RETRY_INTERVAL=1

# --- Sanity Checks ---

# 1. Check for root privileges.
if [[ $EUID -ne 0 ]]; then
   echo -e "${COLOR_ERROR}This script must be run as root. Please use 'sudo'.${COLOR_NONE}"
   exit 1
fi

# 2. Check if an interface name was provided.
if [[ -z "$1" ]]; then
    echo -e "${COLOR_ERROR}Error: No wireless interface specified.${COLOR_NONE}"
    echo "Usage: sudo $0 <interface_name>"
    echo ""
    echo "Available wireless interfaces:"
    iw dev | grep 'Interface' | awk '{print "  - " $2}' || echo "  (Could not find any)"
    exit 1
fi

INTERFACE=$1

# 3. Verify that the provided interface exists.
if ! iw dev "$INTERFACE" info >/dev/null 2>&1; then
    echo -e "${COLOR_ERROR}Error: Interface '$INTERFACE' does not exist or is not a wireless device.${COLOR_NONE}"
    echo "Please choose from the available interfaces:"
    iw dev | grep 'Interface' | awk '{print "  - " $2}' || echo "  (Could not find any)"
    exit 1
fi

echo "Using specified wireless interface: $INTERFACE"

# 4. Ensure the wireless interface is up.
ip link set "$INTERFACE" up || {
    echo -e "${COLOR_ERROR}Error: Could not bring up interface $INTERFACE.${COLOR_NONE}"
    exit 1
}

# --- Main Logic ---

SCAN_OUTPUT=""
echo -n "Scanning for networks (will wait up to ${SCAN_TIMEOUT}s)..."

for (( i=0; i<SCAN_TIMEOUT; i+=RETRY_INTERVAL )); do
    SCAN_OUTPUT=$(iw dev "$INTERFACE" scan)
    if echo "$SCAN_OUTPUT" | grep -q "SSID:"; then
        echo " Success!"
        break
    fi
    echo -n "."
    sleep "$RETRY_INTERVAL"
done

if ! echo "$SCAN_OUTPUT" | grep -q "SSID:"; then
    echo -e " ${COLOR_ERROR}Timeout!${COLOR_NONE}"
    echo -e "${COLOR_ERROR}Could not find any networks after ${SCAN_TIMEOUT} seconds.${COLOR_NONE}"
fi

echo ""

# Process the stored SCAN_OUTPUT.
echo "$SCAN_OUTPUT" | awk -v bold="${COLOR_HEADER}" -v normal="${COLOR_NONE}" '
BEGIN {
    printf "%s%-25s %-10s %-15s %s%s\n", bold, "SSID", "CHANNEL", "SIGNAL (dBm)", "SECURITY", normal;
    printf "%s%-25s %-10s %-15s %s%s\n", bold, "-------------------------", "----------", "---------------", "----------", normal;
    network_count = 0;
}
/^BSS/ {
    if (ssid) {
        if (!security) { security = "Open" }
        printf "%-25s %-10s %-15s %s\n", ssid, channel, signal, security;
        network_count++;
    }
    ssid=""; signal="-"; security=""; channel="-";
}
/SSID:/ {
    match($0, /SSID: .*/);
    ssid = substr($0, RSTART + 6, RLENGTH - 6);
}
/signal:/ {
    signal = $2;
}
/DS Parameter set: channel/ {
    channel = $5;
}
/RSN/ { security = "WPA2/WPA3"; }
/WPA/ && !/RSN/ { if (!security) { security = "WPA"; } }
END {
    if (ssid) {
        if (!security) { security = "Open"; }
        printf "%-25s %-10s %-15s %s\n", ssid, channel, signal, security;
        network_count++;
    }
    if (network_count == 0) {
        print "No networks found.";
    }
}'

echo ""
echo "Scan complete."
