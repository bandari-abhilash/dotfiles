#!/bin/bash

# Toggle volume slider width

WIDTH=100
CURRENT_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")

if [ "$CURRENT_WIDTH" -eq "0" ]; then
  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
else
  sketchybar --animate tanh 30 --set volume slider.width=0
fi
