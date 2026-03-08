# My macOS Dotfiles

A highly customized and aesthetic macOS setup utilizing [AeroSpace](https://github.com/nikitabobko/AeroSpace) (a tiling window manager) and [SketchyBar](https://github.com/FelixKratz/SketchyBar) (a highly customizable macOS status bar replacement).

Inspired by the clean styling of the SketchyBar creator, **FelixKratz**, merged with slick interactive Apple-style popups inspired by **Pe8er**.

## Features
- **Aesthetic**: Catppuccin Macchiato floating bar (`0xa024273a`), blurred backgrounds. 
- **Modular**: GNU Stow compatible folder structure.
- **Smart Workspaces**: AeroSpace dynamic workspace numbering with live mapped App icons using `sketchybar-app-font`.
- **Interactive**: Fully clickable Wi-Fi popups parsing SSID and IPs, and click-to-expand Volume sliders.
- **Clean**: Auto-hiding battery that only shows when discharging below 60%.

## Omakub-Style Theming Engine
We have included a simple theming engine that lets you hot-swap palettes across the bar instantly, inspired by [Omakub by Basecamp](https://omakub.org/).

**This engine will automatically flip your macOS desktop wallpaper** concurrently to match the chosen theme!

Available themes:
- `catppuccin` (Macchiato)
- `tokyo-night` (Omarchy/Omakub style)

**To change your theme instantly:**
```bash
~/dotfiles/bin/set-theme tokyo-night
```

## Prerequisites
- macOS

## Installation (1-Click)

The included `install.sh` script will automatically install Homebrew, tap the required repositories, install all tools (`sketchybar`, `aerospace`, `stow`, `jq`), install the required fonts, and securely symlink the configs using GNU Stow.

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## Structure
```
dotfiles/
├── aerospace/
│   └── .config/
│       └── aerospace/
└── sketchybar/
    └── .config/
        └── sketchybar/
```

Everything in this repository is symlinked directly into your `~/.config` folder via GNU Stow.
