# Halow CLI Utilities

A collection of lightweight bash scripts for scanning, connecting, and monitoring wireless interfaces using `iw`, `wpa_supplicant`, and `dhclient`.

## 🛠 Prerequisites
* **Hardware**: A Linux-compatible wireless interface.
* **Binaries**: `iw`, `iproute2`, `wpa_supplicant` (or `wpa_supplicant_s1g`), `dhclient`, and `sudo`.

## 🚀 Installation
1. Clone this repository.
2. Make scripts executable:
```
chmod +x *.sh halow
```
3. Add to the path
```
sudo ln -s $(pwd)/halow /usr/local/bin/halow
sudo ln -s $(pwd)/wifi-list.sh /usr/local/bin/wifi-list.sh
sudo ln -s $(pwd)/wifi-connect.sh /usr/local/bin/wifi-connect.sh
sudo ln -s $(pwd)/wifi-stats.sh /usr/local/bin/wifi-stats.sh
sudo ln -s $(pwd)/rpi_monitor_pro.sh /usr/local/bin/rpi_monitor_pro.sh
```
## ⌨️ Usage
### Scan for Networks
Scan for available access points using a specific interface.
```
halow list wlan0
```
### Connect to a Network
Start wpa_supplicant and obtain a DHCP lease using a config file.
```
halow connect wlan0 wpa_supplicant.conf
```
### Monitor Stats
View real-time signal strength and bitrate.
```
halow stats wlan0
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
