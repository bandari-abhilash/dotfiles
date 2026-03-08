#!/bin/bash

# Wi-Fi icon and popup data logic

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

SSID=$(networksetup -getairportnetwork en0 2>/dev/null | awk -F': ' '{print $2}')
IP=$(ipconfig getifaddr en0)

if [ "$SSID" = "" ] || [ "$SSID" = "You are not associated with an AirPort network." ]; then
  sketchybar --set "$NAME" icon="$WIFI_OFF" icon.color=$GREY \
             --set wifi.ssid label="Not Connected" \
             --set wifi.ipaddress label="No IP"
else
  sketchybar --set "$NAME" icon="$WIFI" icon.color=$WHITE \
             --set wifi.ssid label="$SSID" \
             --set wifi.ipaddress label="$IP"
fi
