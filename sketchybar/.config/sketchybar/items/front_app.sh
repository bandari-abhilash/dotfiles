#!/bin/bash

# Front app — shows focused app name (simplified from FelixKratz, no yabai)

front_app=(
  script="sketchybar --set \$NAME label=\"\$INFO\""
  icon.drawing=off
  padding_left=0
  label.color=$WHITE
  label.font="$FONT:Bold:12.0"
  associated_display=active
)

sketchybar --add item front_app left             \
           --set front_app "${front_app[@]}"     \
           --subscribe front_app front_app_switched
