#!/bin/bash
# Install Oh My Tmux if not present
set -euo pipefail

OH_MY_TMUX_DIR="$HOME/.local/share/tmux/oh-my-tmux"

if [ ! -d "$OH_MY_TMUX_DIR" ]; then
  echo "Installing Oh My Tmux..."
  mkdir -p "$(dirname "$OH_MY_TMUX_DIR")"
  git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR"

  # Create symlink for tmux.conf
  mkdir -p "$HOME/.config/tmux"
  ln -sf "$OH_MY_TMUX_DIR/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
  echo "Oh My Tmux installed."
else
  echo "Oh My Tmux already installed."
fi
