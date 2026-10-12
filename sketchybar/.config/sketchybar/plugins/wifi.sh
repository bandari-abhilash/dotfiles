#!/bin/bash

# Wi-Fi icon and popup data logic

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

# Wi-Fi isn't always en0, so look it up
IFACE=$(networksetup -listallhardwareports | awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; print $2; exit }')
IFACE=${IFACE:-en0}

IP=$(ipconfig getifaddr "$IFACE")

# Since macOS 14.4 the SSID is redacted for processes without Location
# Services access, so fall back to a generic label when it's hidden
SSID=$(ipconfig getsummary "$IFACE" 2>/dev/null | awk -F ' SSID : ' '/ SSID : / { print $2; exit }')
if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
  SSID="Connected"
fi

if [ -z "$IP" ]; then
  sketchybar --set "$NAME" icon="$WIFI_OFF" icon.color=$GREY \
             --set wifi.ssid label="Not Connected" \
             --set wifi.ipaddress label="No IP"
else
  sketchybar --set "$NAME" icon="$WIFI" icon.color=$WHITE \
             --set wifi.ssid label="$SSID" \
             --set wifi.ipaddress label="$IP"
fi
