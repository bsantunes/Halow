# Halow CLI Utilities

A collection of lightweight bash scripts for scanning, connecting, and monitoring wireless interfaces using `iw`, `wpa_supplicant`, and `dhclient`.

## 🛠 Prerequisites
* **Hardware**: A Linux-compatible wireless interface.
* **Binaries**: `iw`, `iproute2`, `wpa_supplicant` (or `wpa_supplicant_s1g`), `dhclient`, and `sudo`.

## 🚀 Installation
1. Clone this repository.
2. Make scripts executable:
```
chmod +x wifi-*.sh halow
```
3. Add to the path
```
sudo ln -s $(pwd)/halow /usr/local/bin/halow
```
## 📋 Script Overview
### wifi-list.sh
Scans for available networks and displays them in a formatted table.
```
Usage: ./wifi-list.sh <interface> [--reg <COUNTRY_CODE>]
```
```
Example: ./wifi-list.sh wlan0 --reg EU
```
### wifi-connect.sh
Connects to a network using a provided wpa_supplicant configuration file.
```
Usage: ./wifi-connect.sh <interface> <config_file>
```
```
Example: ./wifi-connect.sh wlan0 my_wifi.conf
```
Note: This script handles stale socket cleanup and automatically requests an IP via DHCP.

### wifi-stats.sh
Real-time monitor for signal strength and bitrate of the current connection.
```
Usage: ./wifi-stats.sh <interface>
```
```
Example: ./wifi-stats.sh wlan0
```
