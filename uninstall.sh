#!/usr/bin/env bash

# Dotfiles Uninstaller for macOS
# This script undoes what install.sh did: it stops services, unstows configs,
# restores backups (if any), removes fonts, and uninstalls Homebrew packages
# (if they were installed via Homebrew).

set -euo pipefail

# ─── Resolve script location ───
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}==> WARNING: This will uninstall SketchyBar, skhd, AeroSpace, and remove your symlinked configs.${NC}"
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Uninstall cancelled.${NC}"
    exit 0
fi

# Make sure brew is available
if ! command -v brew &> /dev/null; then
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# ─── 1. Stop Services ────────────────────────────────────────────────────────
echo -e "${BLUE}==> Stopping services...${NC}"
if command -v sketchybar &> /dev/null; then
    brew services stop sketchybar 2>/dev/null || true
fi

if command -v skhd &> /dev/null; then
    # skhd manages its own launchd plist
    skhd --stop-service 2>/dev/null || true
fi

# Note: AeroSpace is an app, not a service. User can quit it manually.
# skhd is only present on setups installed before hotkeys moved into AeroSpace.

# ─── 2. Un-stow Configs ──────────────────────────────────────────────────────
echo -e "${BLUE}==> Removing symlinks via GNU Stow...${NC}"
cd "$DOTFILES_DIR"
for pkg in aerospace sketchybar skhd; do
    if [ -d "$HOME/.config/$pkg" ] && [ -L "$HOME/.config/$pkg" ]; then
        echo "  Unstowing $pkg..."
        stow --delete --target="$HOME" "$pkg" 2>/dev/null || true
    fi
done

# ─── 3. Restore Backups ──────────────────────────────────────────────────────
echo -e "${BLUE}==> Restoring backed-up configs (if any)...${NC}"
for folder in aerospace sketchybar skhd; do
    if [ -d "$HOME/.config/${folder}.backup" ]; then
        echo -e "${YELLOW}  Restoring ~/.config/${folder}.backup -> ~/.config/$folder${NC}"
        # Make sure the symlink is gone before moving
        rm -rf "$HOME/.config/$folder" 2>/dev/null || true
        mv "$HOME/.config/${folder}.backup" "$HOME/.config/$folder" 2>/dev/null || true
    fi
done

# ─── 4. Remove Fonts ─────────────────────────────────────────────────────────
echo -e "${BLUE}==> Removing fonts...${NC}"
if [ -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ]; then
    echo "  Removing sketchybar-app-font.ttf..."
    rm -f "$HOME/Library/Fonts/sketchybar-app-font.ttf"
fi
rm -f "$DOTFILES_DIR/sketchybar/.config/sketchybar/plugins/icon_map.sh"

# We prompt for Hack Nerd Font since they might use it for other things
if brew list --cask 2>/dev/null | grep -q "^font-hack-nerd-font$"; then
    read -p "Do you want to uninstall Hack Nerd Font? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew uninstall --cask font-hack-nerd-font 2>/dev/null || true
    fi
fi

# ─── 5. Uninstall Homebrew Packages ──────────────────────────────────────────
echo -e "${BLUE}==> Uninstalling Homebrew tools...${NC}"

# We only prompt for stow and jq since they are common general-purpose tools
for pkg in aerospace sketchybar skhd stow jq; do
    if brew list --formula 2>/dev/null | grep -q "^$pkg$" || brew list --cask 2>/dev/null | grep -q "^$pkg$"; then
        if [[ "$pkg" == "stow" || "$pkg" == "jq" ]]; then
            read -p "Do you want to uninstall '$pkg'? (You might be using it elsewhere) (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                continue
            fi
        fi

        echo "  Uninstalling $pkg..."
        if brew info --cask "$pkg" &>/dev/null; then
            brew uninstall --cask "$pkg" 2>/dev/null || true
        else
            brew uninstall "$pkg" 2>/dev/null || true
        fi
    fi
done

# ─── 6. Clean Taps (Optional) ────────────────────────────────────────────────
echo -e "${BLUE}==> Cleaning up taps...${NC}"
for tap in "felixkratz/formulae" "nikitabobko/tap" "koekeishiya/formulae"; do
    if brew tap | grep -q "^$tap$"; then
        # Check if any formulae from this tap are still installed
        if ! brew list --formula | grep -q "^$(basename "$tap")/" 2>/dev/null; then
            echo "  Untapping $tap..."
            brew untap "$tap" 2>/dev/null || true
        fi
    fi
done

# ─── Done ────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}==> Uninstallation Complete!${NC}"
echo "    If you want to remove the dotfiles folder completely, run:"
echo -e "    ${YELLOW}rm -rf $DOTFILES_DIR${NC}"
