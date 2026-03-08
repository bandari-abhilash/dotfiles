#!/usr/bin/env bash

# Dotfiles One-Click Installer for macOS
# This script installs Homebrew, dependencies, fonts, and sets up SketchyBar, AeroSpace & skhd using GNU Stow.
# It supports being run from any location (e.g., ~/Desktop/dotfiles, ~/dotfiles, etc.)
# If anything fails after changes are made, all changes are automatically rolled back.

set -euo pipefail

# ─── Resolve script location (works regardless of where the repo is cloned) ───
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ─── Rollback state tracking ───────────────────────────────────────────────────
INSTALLED_FORMULAE=()
INSTALLED_CASKS=()
INSTALLED_TAPS=()
STOWED_PACKAGES=()
BACKED_UP_CONFIGS=()
SKETCHYBAR_FONT_INSTALLED=false

# ─── Cleanup / Rollback function ───────────────────────────────────────────────
rollback() {
    echo -e "\n${RED}==> An error occurred. Rolling back all changes...${NC}"

    # Un-stow any packages that were stowed
    # ${arr[@]+"${arr[@]}"} guard prevents 'unbound variable' (set -u) when array is empty
    for pkg in ${STOWED_PACKAGES[@]+"${STOWED_PACKAGES[@]}"}; do
        echo -e "${YELLOW}  Removing stow symlinks for: $pkg${NC}"
        stow --delete --target="$HOME" "$pkg" -d "$DOTFILES_DIR" 2>/dev/null || true
    done

    # Restore backed-up configs
    for folder in ${BACKED_UP_CONFIGS[@]+"${BACKED_UP_CONFIGS[@]}"}; do
        if [ -d "$HOME/.config/${folder}.backup" ]; then
            echo -e "${YELLOW}  Restoring backup: ~/.config/${folder}.backup -> ~/.config/$folder${NC}"
            rm -rf "$HOME/.config/$folder" 2>/dev/null || true
            mv "$HOME/.config/${folder}.backup" "$HOME/.config/$folder" 2>/dev/null || true
        fi
    done

    # Remove sketchybar app font if we installed it
    if [ "$SKETCHYBAR_FONT_INSTALLED" = true ]; then
        echo -e "${YELLOW}  Removing sketchybar-app-font...${NC}"
        rm -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" 2>/dev/null || true
    fi

    # Uninstall casks/formulae we installed (in reverse order)
    for cask in ${INSTALLED_CASKS[@]+"${INSTALLED_CASKS[@]}"}; do
        echo -e "${YELLOW}  Uninstalling cask: $cask${NC}"
        brew uninstall --cask "$cask" 2>/dev/null || true
    done

    for formula in ${INSTALLED_FORMULAE[@]+"${INSTALLED_FORMULAE[@]}"}; do
        echo -e "${YELLOW}  Uninstalling formula: $formula${NC}"
        brew uninstall "$formula" 2>/dev/null || true
    done

    # Untap repos we added
    for tap in ${INSTALLED_TAPS[@]+"${INSTALLED_TAPS[@]}"}; do
        echo -e "${YELLOW}  Untapping: $tap${NC}"
        brew untap "$tap" 2>/dev/null || true
    done

    echo -e "${RED}==> Rollback complete. Your system has been restored to its previous state.${NC}"
    exit 1
}

trap rollback ERR

# ─── Helper: check if a tap is already installed ───────────────────────────────
tap_installed() {
    brew tap | grep -q "^$1$"
}

# ─── Helper: check if a formula/cask is already installed ─────────────────────
formula_installed() {
    brew list --formula 2>/dev/null | grep -q "^$1$"
}

cask_installed() {
    brew list --cask 2>/dev/null | grep -q "^$1$"
}

# ─── 1. Homebrew ───────────────────────────────────────────────────────────────
echo -e "${BLUE}==> Starting Dotfiles Installation...${NC}"
echo -e "${BLUE}==> Dotfiles directory: $DOTFILES_DIR${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "${BLUE}==> Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Set up brew in PATH for both Apple Silicon and Intel Macs
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}==> Homebrew is already installed.${NC}"
fi

# ─── 2. Taps ───────────────────────────────────────────────────────────────────
echo -e "${BLUE}==> Tapping required Homebrew repositories...${NC}"

if ! tap_installed "felixkratz/formulae"; then
    brew tap FelixKratz/formulae
    INSTALLED_TAPS+=("felixkratz/formulae")
else
    echo -e "${GREEN}  felixkratz/formulae already tapped.${NC}"
fi

if ! tap_installed "nikitabobko/tap"; then
    brew tap nikitabobko/tap
    INSTALLED_TAPS+=("nikitabobko/tap")
else
    echo -e "${GREEN}  nikitabobko/tap already tapped.${NC}"
fi

# skhd lives in koekeishiya/formulae (not homebrew/core)
if ! tap_installed "koekeishiya/formulae"; then
    brew tap koekeishiya/formulae
    INSTALLED_TAPS+=("koekeishiya/formulae")
else
    echo -e "${GREEN}  koekeishiya/formulae already tapped.${NC}"
fi

# ─── 3. Core formulae ─────────────────────────────────────────────────────────
echo -e "${BLUE}==> Installing core tools (stow, jq, sketchybar, skhd, aerospace)...${NC}"

for formula in stow jq sketchybar; do
    if ! formula_installed "$formula"; then
        brew install "$formula"
        INSTALLED_FORMULAE+=("$formula")
    else
        echo -e "${GREEN}  $formula already installed.${NC}"
    fi
done

# skhd is not in homebrew/core — must install from its own tap
if ! formula_installed "skhd"; then
    brew install koekeishiya/formulae/skhd
    INSTALLED_FORMULAE+=("skhd")
else
    echo -e "${GREEN}  skhd already installed.${NC}"
fi

if ! cask_installed "aerospace"; then
    brew install --cask aerospace
    INSTALLED_CASKS+=("aerospace")
else
    echo -e "${GREEN}  aerospace already installed.${NC}"
fi

# ─── 4. Fonts ─────────────────────────────────────────────────────────────────
echo -e "${BLUE}==> Installing Nerd Fonts...${NC}"

if ! cask_installed "font-hack-nerd-font"; then
    brew install --cask font-hack-nerd-font
    INSTALLED_CASKS+=("font-hack-nerd-font")
else
    echo -e "${GREEN}  font-hack-nerd-font already installed.${NC}"
fi

echo -e "${BLUE}==> Downloading sketchybar-app-font...${NC}"
if [ ! -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ]; then
    curl -sL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.5/sketchybar-app-font.ttf \
        -o "$HOME/Library/Fonts/sketchybar-app-font.ttf"
    SKETCHYBAR_FONT_INSTALLED=true
else
    echo -e "${GREEN}  sketchybar-app-font already installed.${NC}"
fi

# ─── 5. GNU Stow ──────────────────────────────────────────────────────────────
echo -e "${BLUE}==> Applying dotfiles via GNU Stow...${NC}"

cd "$DOTFILES_DIR"

# Back up any existing non-symlink configs
for folder in aerospace sketchybar skhd; do
    if [ -d "$HOME/.config/$folder" ] && [ ! -L "$HOME/.config/$folder" ]; then
        echo -e "${YELLOW}  Backing up existing $folder config to ~/.config/${folder}.backup${NC}"
        mv "$HOME/.config/$folder" "$HOME/.config/${folder}.backup"
        BACKED_UP_CONFIGS+=("$folder")
    fi
done

# Stow each package
for pkg in aerospace sketchybar skhd; do
    stow --restow --target="$HOME" "$pkg"
    STOWED_PACKAGES+=("$pkg")
done

# ─── 6. Start services ────────────────────────────────────────────────────────
echo -e "${BLUE}==> Starting SketchyBar...${NC}"
brew services start sketchybar

echo -e "${BLUE}==> Starting skhd...${NC}"
# skhd manages its own launchd plist — do not use brew services
skhd --start-service

# ─── 7. skhd Accessibility Permission ────────────────────────────────────────
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  ACTION REQUIRED: Grant Accessibility Permission to skhd${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  skhd needs Accessibility access to intercept key events."
echo -e "  Opening System Settings → Privacy & Security → Accessibility...\n"
echo -e "  ${BLUE}Steps:${NC}"
echo -e "   1. Find 'skhd' in the list and toggle it ON."
echo -e "   2. If skhd is NOT listed, click the '+' button, then in the file picker"
echo -e "      press ${YELLOW}Cmd + Shift + G${NC} to open 'Go to Folder', type:"
echo -e "      ${BLUE}/opt/homebrew/bin${NC}  → select 'skhd' → click Open."
echo -e "   3. Toggle skhd ON, then come back here and press Enter."
echo -e "   4. After granting permission, skhd will start intercepting keys.\n"

# Open the Accessibility pane directly
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo -n "  Press [Enter] once you have granted Accessibility permission..."
read -r

# Restart skhd now that it has permission
echo -e "${BLUE}==> Restarting skhd with new permissions...${NC}"
skhd --restart-service

# ─── Done ─────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}==> Installation Complete!${NC}"
echo -e "${GREEN}    SketchyBar, skhd, and AeroSpace configs are now symlinked and active.${NC}"
echo "    Note: You may need to start AeroSpace manually from your Applications folder for the first time."
echo "    skhd keybindings are live — use alt+shift+s to reload skhd after any edits."

