#!/usr/bin/env bash

# Dotfiles One-Click Installer for macOS
# This script installs Homebrew, dependencies, fonts, and sets up SketchyBar & AeroSpace using GNU Stow.

set -e # Exit immediately if a command exits with a non-zero status

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==> Starting Dotfiles Installation...${NC}"

# 1. Check for Homebrew, install if not present
if ! command -v brew &> /dev/null; then
    echo -e "${BLUE}==> Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo -e "${GREEN}==> Homebrew is already installed.${NC}"
fi

# 2. Add required Homebrew taps
echo -e "${BLUE}==> Tapping required Homebrew repositories...${NC}"
brew tap FelixKratz/formulae
brew tap nikitabobko/tap

# 3. Install core dependencies
echo -e "${BLUE}==> Installing core tools (stow, jq, sketchybar, aerospace)...${NC}"
brew install stow jq sketchybar aerospace

# 4. Install fonts
echo -e "${BLUE}==> Installing Nerd Fonts...${NC}"
brew install --cask font-hack-nerd-font

echo -e "${BLUE}==> Downloading sketchybar-app-font...${NC}"
curl -sL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.5/sketchybar-app-font.ttf -o "$HOME/Library/Fonts/sketchybar-app-font.ttf"

# 5. Setup GNU Stow
echo -e "${BLUE}==> Applying dotfiles via GNU Stow...${NC}"
cd "$HOME/dotfiles" || exit 1

# If current configs exist and are not symlinks, back them up
for folder in aerospace sketchybar; do
    if [ -d "$HOME/.config/$folder" ] && [ ! -L "$HOME/.config/$folder" ]; then
        echo "Backing up existing $folder configuration to ~/.config/${folder}.backup"
        mv "$HOME/.config/$folder" "$HOME/.config/${folder}.backup"
    fi
done

# Run stow
stow --restow --target="$HOME" aerospace
stow --restow --target="$HOME" sketchybar

# 6. Start services
echo -e "${BLUE}==> Starting SketchyBar...${NC}"
brew services start sketchybar

echo -e "${GREEN}==> Installation Complete! The SketchyBar and AeroSpace configs are now symlinked and active.${NC}"
echo "Note: You may need to start AeroSpace manually from your Applications folder for the first time."
