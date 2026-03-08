#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

sketchybar --set "$NAME" label="$(date '+%a %b %-d %-l:%M %p')" label.color=$BLACK
