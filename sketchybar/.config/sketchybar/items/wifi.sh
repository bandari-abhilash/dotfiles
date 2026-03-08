#!/bin/bash

# Wi-Fi status icon with interactive popup

wifi_item=(
  icon=$WIFI
  icon.font="Hack Nerd Font:Bold:16.0"
  icon.color=$WHITE
  label.drawing=off
  padding_left=8
  padding_right=4
  update_freq=30
  script="$PLUGIN_DIR/wifi.sh"
  click_script="sketchybar --set \$NAME popup.drawing=toggle"
)

sketchybar --add item wifi right       \
           --set wifi "${wifi_item[@]}" \
                                        \
           --add item wifi.ssid popup.wifi \
           --set wifi.ssid icon="󰤨" label="SSID" click_script="open 'x-apple.systempreferences:com.apple.preference.network?Wi-Fi'; sketchybar --set wifi popup.drawing=off" \
                                        \
           --add item wifi.ipaddress popup.wifi \
           --set wifi.ipaddress icon="󰩟" label="IP Address" click_script="sketchybar --set wifi popup.drawing=off"
