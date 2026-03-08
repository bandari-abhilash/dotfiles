#!/bin/bash

# Workspace items — adapted from FelixKratz for AeroSpace

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7")

sketchybar --add event aerospace_workspace_change

for i in "${!SPACE_ICONS[@]}"
do
  sid=$(($i+1))

  space=(
    icon=${SPACE_ICONS[i]}
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    label.padding_right=20
    icon.highlight_color=$RED
    label.font="sketchybar-app-font:Regular:16.0"
    label.background.height=26
    label.background.drawing=on
    label.background.color=$BACKGROUND_2
    label.background.corner_radius=8
    label.drawing=off
    script="$PLUGIN_DIR/aerospace.sh $sid"
    click_script="aerospace workspace $sid"
  )

  sketchybar --add item space.$sid left               \
             --set space.$sid "${space[@]}"            \
             --subscribe space.$sid aerospace_workspace_change front_app_switched system_woke space_change
done

# Bracket around all spaces
spaces=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=2
  background.drawing=on
)

separator=(
  icon=􀆊
  icon.font="$FONT:Bold:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  associated_display=active
  icon.color=$WHITE
)

sketchybar --add bracket spaces '/space\..*/' \
           --set spaces "${spaces[@]}"        \
                                              \
           --add item separator left          \
           --set separator "${separator[@]}"
