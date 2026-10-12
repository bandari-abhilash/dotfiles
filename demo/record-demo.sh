#!/usr/bin/env bash

# Records a demo of this setup: a mock incident call driven entirely from the keyboard.
# It covers the app workspaces (⌥ 1–4, ⌥ 7), moving between panes (⌥ H/J/K/L), stacking and
# overlapping windows (⌥ / and ⌥ ,), and the app launchers (⌥ A/B/S/P). Before each step,
# a large banner below the bar shows the keys and what they do; the step then runs the same
# command that shortcut runs. Logs, metrics and deploys are synthetic (see fake-logs.sh).
#
# Usage: demo/record-demo.sh [output-dir]       (default: demo/out)
#
# Settings (environment variables):
#   DEMO_DISPLAY=1                     display to record (1 = main)
#   DASHBOARD_URL=https://play.grafana.org           opened in Arc (workspace 2)
#   RUNBOOK_URL=https://github.com/bandari-abhilash/dotfiles   opened in Brave (workspace 3)

set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${1:-$DEMO_DIR/out}"
DEMO_DISPLAY="${DEMO_DISPLAY:-1}"
DASHBOARD_URL="${DASHBOARD_URL:-https://play.grafana.org}"
RUNBOOK_URL="${RUNBOOK_URL:-https://github.com/bandari-abhilash/dotfiles}"

# The apps the launchers and window rules in aerospace.toml use
DEMO_APPS=("Arc" "Brave Browser" "Slack" "Postman")
PARK_WS="demo-parked"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ─── Storyboard: keys | what it does | command | seconds to hold ──────────────
# Workspace 1 holds three panes: logs | metrics | deploys. `recover` rolls back the fake incident.
STEPS=(
    "|Production alert: checkout errors|aerospace workspace 1|3"
    "⌥ L|Next pane: live metrics|aerospace focus right|2"
    "⌥ L|Next pane: deploy history|aerospace focus right|2.5"
    "⌥ /|Stack the panes|aerospace layout tiles horizontal vertical|2.5"
    "⌥ K|Up a pane|aerospace focus up|1.5"
    "⌥ K|Up again: the logs|aerospace focus up|2"
    "⌥ J|Down a pane|aerospace focus down|1.5"
    "⌥ /|Side by side again|aerospace layout tiles horizontal vertical|2"
    "⌥ ,|Overlap them in a stack|aerospace layout accordion horizontal vertical|2.5"
    "⌥ H|Previous window in the stack|aerospace focus left|2"
    "⌥ L|Next window in the stack|aerospace focus right|2"
    "⌥ /|Tile them again|aerospace layout tiles horizontal vertical|2"
    "⌥ 2|Workspace 2: dashboards|aerospace workspace 2|3"
    "⌥ 3|Workspace 3: runbook|aerospace workspace 3|3"
    "⌥ 4|Workspace 4: incident channel|aerospace workspace 4|3"
    "⌥ 7|Workspace 7: API checks|aerospace workspace 7|3"
    "⌥ A|Open Arc from anywhere|open -a Arc|2.5"
    "⌥ S|Open Slack|open -a Slack|2.5"
    "⌥ B|Open Brave|open -a 'Brave Browser'|2.5"
    "⌥ P|Open Postman|open -a Postman|2.5"
    "⌥ Tab|Back to the previous workspace|aerospace workspace-back-and-forth|2.5"
    "⌥ 1|Rolled back: errors are gone|recover; aerospace workspace 1|5"
    "|Every app has an address|:|3"
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

missing=()
for app in "${DEMO_APPS[@]}"; do
    open -Ra "$app" &> /dev/null || missing+=("$app")
done

# Each step holds for its time plus 0.6s to read the banner; 2s spare at the end
DURATION=$(printf '%s\n' "${STEPS[@]}" | awk -F'|' '{ t += $NF + 0.6 } END { printf "%d", t + 3 }')

echo -e "${BLUE}==> Demo recording (~${DURATION}s of display $DEMO_DISPLAY)${NC}"
echo -e "${YELLOW}  Everything visible on that display will be recorded:${NC}"
echo "   • Turn on Do Not Disturb so notifications don't appear."
echo "   • Arc and Brave show their open tabs. Close private ones or hide the sidebar."
echo "   • Slack (workspace 4) and Postman (workspace 7) are shown as they are."
echo "     Open a channel and a request that are safe to publish first."
echo "   • Other windows on workspaces 1–7 are moved aside and put back afterwards."
echo "   • Your terminal's Screen Recording permission is needed (System Settings → Privacy & Security)."
echo "   • Hands off the keyboard and mouse until it finishes."
if [ "${#missing[@]}" -gt 0 ]; then
    echo -e "${YELLOW}  Not installed, so their workspaces will be empty: ${missing[*]}${NC}"
fi
read -r -p "  Ready? (y/N) " reply
[[ "$reply" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

mkdir -p "$OUT_DIR"
MOV="$OUT_DIR/aerospace-demo.mov"
MP4="$OUT_DIR/aerospace-demo.mp4"
rm -f "$MOV"

source "$HOME/.config/sketchybar/colors.sh"
START_WS="$(aerospace list-workspaces --focused)"
RECOVER_FLAG="$(mktemp -u "${TMPDIR:-/tmp}/demo-recover.XXXXXX")"
PARKED=()

is_demo_app() {
    local app
    for app in "${DEMO_APPS[@]}"; do
        [ "$1" = "$app" ] && return 0
    done
    return 1
}

recover() {
    touch "$RECOVER_FLAG"
}

cleanup() {
    sketchybar --remove demo.keys &> /dev/null || true
    rm -f "$RECOVER_FLAG"
    local entry
    for entry in ${PARKED[@]+"${PARKED[@]}"}; do
        aerospace move-node-to-workspace --window-id "${entry%%|*}" "${entry#*|}" &> /dev/null || true
    done
    aerospace workspace "$START_WS" &> /dev/null || true
}
trap cleanup EXIT

# ─── Clear workspaces 1–7 of everything except the demo ───────────────────────
# Windows of other apps, and Terminal windows that were already open, wait on a hidden
# workspace that SketchyBar doesn't show, then go back where they were.
echo -e "${BLUE}==> Moving other windows aside...${NC}"
while IFS='|' read -r id app ws; do
    case "$ws" in
        [1-7]) ;;
        *) continue ;;
    esac
    is_demo_app "$app" && continue
    if aerospace move-node-to-workspace --window-id "$id" "$PARK_WS" &> /dev/null; then
        PARKED+=("$id|$ws")
    fi
done < <(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{workspace}')

# ─── Stage the windows (rules in aerospace.toml put each on its workspace) ────
echo -e "${BLUE}==> Opening demo windows...${NC}"
open -a Arc "$DASHBOARD_URL" &> /dev/null || true
open -a "Brave Browser" "$RUNBOOK_URL" &> /dev/null || true
open -a Slack &> /dev/null || true
open -a Postman &> /dev/null || true
sleep 4

# Terminal windows open last, so the fake incident starts as the recording does
for mode in logs metrics deploys; do
    osascript -e "tell application \"Terminal\" to do script \"clear; DEMO_RECOVER_FLAG='$RECOVER_FLAG' bash '$DEMO_DIR/fake-logs.sh' $mode\"" > /dev/null
    sleep 0.5
done
sleep 1.5
aerospace workspace 1
aerospace layout tiles horizontal &> /dev/null || true
aerospace focus left &> /dev/null || true
aerospace focus left &> /dev/null || true  # start on the logs pane

# A banner below the right side of the bar: the keys in large type, what they do underneath
sketchybar --add item demo.keys right \
           --set demo.keys icon.drawing=off label.drawing=off width=0 padding_right=220 \
                 popup.align=center popup.y_offset=24 \
                 popup.background.color=0xf01a1b26 \
                 popup.background.border_color="$GREEN" popup.background.border_width=2 \
                 popup.background.corner_radius=14 popup.drawing=off \
           --add item demo.keys.combo popup.demo.keys \
           --set demo.keys.combo icon.drawing=off label=" " \
                 label.font="Hack Nerd Font:Bold:44.0" label.color="$GREEN" \
                 label.padding_left=28 label.padding_right=28 background.height=78 \
           --add item demo.keys.desc popup.demo.keys \
           --set demo.keys.desc icon.drawing=off label=" " \
                 label.font="Hack Nerd Font:Regular:20.0" label.color="$WHITE" \
                 label.padding_left=28 label.padding_right=28 background.height=40
sleep 1

banner() {
    local keys="$1" text="$2"
    if [ -n "$keys" ]; then
        sketchybar --set demo.keys.combo drawing=on label="$keys"
    else
        sketchybar --set demo.keys.combo drawing=off
    fi
    sketchybar --set demo.keys.desc label="$text" --set demo.keys popup.drawing=on
}

# ─── Record ───────────────────────────────────────────────────────────────────
echo -e "${BLUE}==> Recording...${NC}"
screencapture -v -V "$DURATION" -D "$DEMO_DISPLAY" "$MOV" &
REC_PID=$!
sleep 1

for step in "${STEPS[@]}"; do
    IFS='|' read -r keys text command hold <<< "$step"
    banner "$keys" "$text"
    sleep 0.6  # let the viewer read the keys before the screen changes
    eval "$command" &> /dev/null || true
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
