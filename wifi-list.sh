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
    echo "Usage: $0 <interface_name> [--reg <COUNTRY_CODE>]"
    echo ""
    echo "Available wireless interfaces:"
    iw dev | grep 'Interface' | awk '{print "  - " $2}' || echo "  (Could not find any)"
    exit 1
fi

INTERFACE=$1

if ! iw dev "$INTERFACE" info >/dev/null 2>&1; then
    echo -e "${COLOR_ERROR}Error: Interface '$INTERFACE' does not exist or is not a wireless device.${COLOR_NONE}"
    exit 1
fi

echo "Using specified wireless interface: $INTERFACE"

# --- Optional Regulatory Domain ---
if [[ "$2" == "--reg" ]]; then
    if [[ -z "$3" ]]; then
        echo -e "${COLOR_ERROR}Error: The --reg flag requires a 2-letter country code (e.g., US, GB, PT).${COLOR_NONE}"
        exit 1
    fi
    REG_DOMAIN=$3
    echo "Setting regulatory domain to $REG_DOMAIN (may require password)..."
    ${SUDO_CMD} iw reg set "$REG_DOMAIN" || {
        echo -e "${COLOR_ERROR}Error: Could not set regulatory domain.${COLOR_NONE}"
        exit 1
    }
    sleep 1
fi

# --- Bring Up Interface ---
echo "Bringing interface up (may require password)..."
${SUDO_CMD} ip link set "$INTERFACE" up || {
    echo -e "${COLOR_ERROR}Error: Could not bring up interface $INTERFACE.${COLOR_NONE}"
    exit 1
}

# --- Main Logic ---

SCAN_OUTPUT=""
echo -n "Scanning for networks (will wait up to ${SCAN_TIMEOUT}s)..."

for (( i=0; i<SCAN_TIMEOUT; i+=RETRY_INTERVAL )); do
    SCAN_OUTPUT=$(${SUDO_CMD} iw dev "$INTERFACE" scan)
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

# --- AWK Parsing (Updated for Frequency) ---
echo "$SCAN_OUTPUT" | awk -v bold="${COLOR_HEADER}" -v normal="${COLOR_NONE}" '
BEGIN {
    # Added FREQ column and adjusted widths
    printf "%s%-25s %-8s %-8s %-15s %s%s\n", bold, "SSID", "FREQ", "CH", "SIGNAL (dBm)", "SECURITY", normal;
    printf "%s%-25s %-8s %-8s %-15s %s%s\n", bold, "-------------------------", "----", "--", "---------------", "----------", normal;
    network_count = 0;
}
/^BSS/ {
    if (ssid) {
        if (!security) { security = "Open" }
        # Added freq variable to the output line
        printf "%-25s %-8s %-8s %-15s %s\n", ssid, freq, channel, signal, security;
        network_count++;
    }
    # Reset variables (including freq)
    ssid=""; freq="-"; signal="-"; security=""; channel="-";
}
/SSID:/ {
    match($0, /SSID: .*/);
    ssid = substr($0, RSTART + 6, RLENGTH - 6);
}
/freq:/ {
    freq = $2;
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
        printf "%-25s %-8s %-8s %-15s %s\n", ssid, freq, channel, signal, security;
        network_count++;
    }
    if (network_count == 0) {
        print "No networks found.";
    }
}'

echo ""
echo "Scan complete."
