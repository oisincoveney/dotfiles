#!/bin/bash
# Install the Catppuccin Mocha theme for bat (delta reuses bat's theme store via
# `syntax-theme`). Idempotent: refetches only if the theme file is missing.
set -euo pipefail

command -v bat >/dev/null 2>&1 || { echo "bat not installed; skipping theme."; exit 0; }

theme_dir="$(bat --config-dir)/themes"
theme_file="$theme_dir/Catppuccin Mocha.tmtheme"

if [ ! -f "$theme_file" ]; then
  echo "Installing Catppuccin Mocha bat theme..."
  mkdir -p "$theme_dir"
  curl -fsSL \
    "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" \
    -o "$theme_file"
fi

# Rebuild bat's theme/syntax cache so `--theme="Catppuccin Mocha"` resolves.
bat cache --build >/dev/null
echo "Catppuccin Mocha theme ready."
