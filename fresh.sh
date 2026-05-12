#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  exec "$DOTFILES_DIR/install.sh"
fi

echo "Setting up macOS..."

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools not found. Installing..."
  xcode-select --install
else
  echo "Xcode Command Line Tools already installed."
fi

"$DOTFILES_DIR/install.sh"

if [[ -r "$DOTFILES_DIR/.macos" ]]; then
  source "$DOTFILES_DIR/.macos"
fi

if command -v claude >/dev/null 2>&1; then
  claude config set -g autoUpdates false || true
fi
