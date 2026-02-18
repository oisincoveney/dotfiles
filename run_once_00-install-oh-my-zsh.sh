#!/bin/bash
# Install Oh My Zsh if not present
set -euo pipefail

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" "" --unattended
  echo "Oh My Zsh installed."
else
  echo "Oh My Zsh already installed."
fi
