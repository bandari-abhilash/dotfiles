#!/usr/bin/env bash

# Records a short demo of this setup: a mock incident call driven entirely from the keyboard.
# Each step shows its shortcut as a caption in SketchyBar, then runs the same AeroSpace
# command that shortcut triggers. Content on screen is synthetic (see fake-logs.sh).
#
# Usage: demo/record-demo.sh [output-dir]       (default: demo/out)
#
# Settings (environment variables):
#   DEMO_DISPLAY=1                     display to record (1 = main)
#   DASHBOARD_APP=Arc                  browser for workspace 2
#   DASHBOARD_URL=https://play.grafana.org
#   RUNBOOK_APP="Brave Browser"        browser for workspace 3
#   RUNBOOK_URL=https://github.com/bandari-abhilash/dotfiles
#   INCLUDE_SLACK=0                    1 adds a Slack step (shows your real Slack!)

set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${1:-$DEMO_DIR/out}"
DEMO_DISPLAY="${DEMO_DISPLAY:-1}"
DASHBOARD_APP="${DASHBOARD_APP:-Arc}"
DASHBOARD_URL="${DASHBOARD_URL:-https://play.grafana.org}"
RUNBOOK_APP="${RUNBOOK_APP:-Brave Browser}"
RUNBOOK_URL="${RUNBOOK_URL:-https://github.com/bandari-abhilash/dotfiles}"
INCLUDE_SLACK="${INCLUDE_SLACK:-0}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ─── Storyboard: caption | aerospace command | seconds to hold ────────────────
STEPS=(
    "Production alert: checkout errors|workspace 1|4"
    "⌥ L   next pane: live metrics|focus right|3"
    "⌥ /   flip the split|layout tiles horizontal vertical|3"
    "⌥ /   flip it back|layout tiles horizontal vertical|2"
    "⌥ 2   dashboards|workspace 2|4"
    "⌥ 3   runbook|workspace 3|4"
)
if [ "$INCLUDE_SLACK" = 1 ]; then
    STEPS+=("⌥ 4   incident channel|workspace 4|4")
fi
STEPS+=(
    "⌥ Tab   back to the dashboard|workspace-back-and-forth|3"
    "⌥ 1   logs: rollback, errors gone|workspace 1|5"
    "Every app has an address|workspace 1|3"
)

# ─── Preflight ────────────────────────────────────────────────────────────────
for cmd in aerospace sketchybar screencapture; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}==> '$cmd' not found. Run install.sh first.${NC}"
        exit 1
    fi
done
if ! aerospace list-workspaces --focused &> /dev/null; then
    echo -e "${RED}==> AeroSpace isn't running. Start it and try again.${NC}"
    exit 1
fi

DURATION=2
for step in "${STEPS[@]}"; do
    DURATION=$((DURATION + ${step##*|}))
done

echo -e "${BLUE}==> Demo recording (~${DURATION}s of display $DEMO_DISPLAY)${NC}"
echo -e "${YELLOW}  Before you start, everything visible on that display will be recorded:${NC}"
echo "   • Turn on Do Not Disturb so notifications don't appear."
echo "   • $DASHBOARD_APP and $RUNBOOK_APP show your open tabs. Close private ones or hide the sidebar."
echo "   • Your terminal's Screen Recording permission is needed (System Settings → Privacy & Security)."
echo "   • Hands off the keyboard and mouse until it finishes."
read -r -p "  Ready? (y/N) " reply
[[ "$reply" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

mkdir -p "$OUT_DIR"
MOV="$OUT_DIR/aerospace-demo.mov"
MP4="$OUT_DIR/aerospace-demo.mp4"
rm -f "$MOV"

source "$HOME/.config/sketchybar/colors.sh"
START_WS="$(aerospace list-workspaces --focused)"

cleanup() {
    sketchybar --remove demo.caption &> /dev/null || true
    aerospace workspace "$START_WS" &> /dev/null || true
}
trap cleanup EXIT

caption() {
    sketchybar --animate tanh 10 --set demo.caption label="$1"
}

# ─── Stage the windows (rules in aerospace.toml put each on its workspace) ────
echo -e "${BLUE}==> Opening demo windows...${NC}"
open -a "$DASHBOARD_APP" "$DASHBOARD_URL" || echo -e "${YELLOW}  $DASHBOARD_APP not installed; workspace 2 will be empty.${NC}"
open -a "$RUNBOOK_APP" "$RUNBOOK_URL" || echo -e "${YELLOW}  $RUNBOOK_APP not installed; workspace 3 will be empty.${NC}"
if [ "$INCLUDE_SLACK" = 1 ]; then
    open -a Slack
fi
sleep 3

# Terminal windows open last, so the fake incident starts as the recording does
osascript -e "tell application \"Terminal\" to do script \"clear; bash '$DEMO_DIR/fake-logs.sh'\"" > /dev/null
osascript -e "tell application \"Terminal\" to do script \"clear; bash '$DEMO_DIR/fake-logs.sh' metrics\"" > /dev/null
sleep 1.5
aerospace workspace 1
aerospace focus left &> /dev/null || true  # start on the logs pane

# The caption sits at the inner edge of the right side of the bar
sketchybar --add item demo.caption right \
           --set demo.caption icon.drawing=off \
                 label.font="Hack Nerd Font:Bold:15.0" \
                 label.color="$BLACK" \
                 label.padding_left=12 label.padding_right=12 \
                 background.color="$GREEN" background.height=26 \
                 background.corner_radius=8 background.drawing=on \
                 padding_right=12 label=" "
sleep 1

# ─── Record ───────────────────────────────────────────────────────────────────
echo -e "${BLUE}==> Recording...${NC}"
screencapture -v -V "$DURATION" -D "$DEMO_DISPLAY" "$MOV" &
REC_PID=$!
sleep 1

for step in "${STEPS[@]}"; do
    IFS='|' read -r text command hold <<< "$step"
    caption "$text"
    # shellcheck disable=SC2086  # command words are split on purpose
    aerospace $command || true
    sleep "$hold"
done

wait "$REC_PID" || true

if [ ! -s "$MOV" ]; then
    echo -e "${RED}==> No recording was saved. Check Screen Recording permission for your terminal.${NC}"
    exit 1
fi

# ─── Export a web-friendly MP4 (H.264, fits in 1920x1080) ─────────────────────
echo -e "${BLUE}==> Exporting MP4...${NC}"
avconvert --source "$MOV" --preset Preset1920x1080 --output "$MP4" --replace > /dev/null

echo -e "\n${GREEN}==> Done.${NC}"
echo "    Original: $MOV"
echo "    Web:      $MP4"
echo "    The demo Terminal windows are still open; close them when you're done."
