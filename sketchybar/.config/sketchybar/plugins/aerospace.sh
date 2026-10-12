#!/bin/bash

# Updates every workspace item in one pass: highlights the focused workspace
# and shows sketchybar-app-font icons for the apps on each workspace.
# Usage: aerospace.sh <workspace ids...>

source "$HOME/.config/sketchybar/colors.sh"

ICON_MAP="$HOME/.config/sketchybar/plugins/icon_map.sh"
LOCK="${TMPDIR:-/tmp}/sketchybar_aerospace.lock"

# Only one update at a time, so a stalled aerospace call can't pile up processes.
# A lock older than 10s belongs to a run that was killed; reclaim it.
if [ -d "$LOCK" ] && [ $(( $(date +%s) - $(stat -f %m "$LOCK") )) -gt 10 ]; then
  rmdir "$LOCK" 2>/dev/null
fi
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# macOS has no `timeout`; perl's alarm survives exec and kills the command
with_timeout() {
  perl -e 'alarm shift; exec @ARGV' "$@"
}

# FOCUSED_WORKSPACE is only passed with aerospace_workspace_change
FOCUSED="${FOCUSED_WORKSPACE:-$(with_timeout 2 aerospace list-workspaces --focused 2>/dev/null)}"
WINDOWS="$(with_timeout 2 aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)"

args=()
for sid in "$@"; do
  icons=""
  if [ -f "$ICON_MAP" ]; then
    while IFS= read -r app; do
      [ -n "$app" ] && icons+="$(bash "$ICON_MAP" "$app")"
    done <<< "$(printf '%s\n' "$WINDOWS" | awk -F'|' -v s="$sid" '$1 == s { print $2 }')"
  fi

  highlight=off
  [ "$sid" = "$FOCUSED" ] && highlight=on

  label_drawing=off
  [ -n "$icons" ] && label_drawing=on

  args+=(--set "space.$sid" icon.highlight=$highlight label.drawing=$label_drawing label="$icons")
done

sketchybar --animate tanh 20 "${args[@]}"
