#!/bin/bash

# AeroSpace workspace plugin adapted to map apps to sketchybar-app-font icons

SID=$1
source "$HOME/.config/sketchybar/plugins/icon_map_fn.sh"

update() {
  WIDTH="dynamic"
  
  # Fetch all apps on this workspace
  APPS=$(aerospace list-windows --workspace $SID --format "%{app-name}" 2>/dev/null)
  
  ICON_STRING=""
  if [ "$APPS" != "" ]; then
    while IFS= read -r app; do
      icon_map_fn "$app"
      ICON_STRING+="$icon_result"
    done <<< "$APPS"
  fi

  if [ "$FOCUSED_WORKSPACE" = "$SID" ]; then
    WIDTH="0"
    sketchybar --animate tanh 20 --set $NAME icon.highlight=on label.width=$WIDTH background.border_color=$BACKGROUND_2 label="$ICON_STRING"
  else
    sketchybar --animate tanh 20 --set $NAME icon.highlight=off label.width=$WIDTH background.border_color=$TRANSPARENT label="$ICON_STRING"
  fi
}

case "$SENDER" in
  "aerospace_workspace_change" | "front_app_switched" | "space_change" | "system_woke")
    update
    ;;
  *)
    update
    ;;
esac
