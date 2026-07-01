#!/bin/bash
# Install Catppuccin Mocha themes for the TUIs (+ a ghostty cursor shader).
# Idempotent: each asset is fetched only if missing. Data-driven — one (url dest)
# table drives the plain-file fetches; tool-specific installs (bat cache rebuild,
# yazi flavor via `ya pkg`) are handled explicitly.
set -euo pipefail

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

fetch() {  # url dest
  local url="$1" dest="$2"
  [ -f "$dest" ] && return 0
  mkdir -p "$(dirname "$dest")"
  if curl -fsSL "$url" -o "$dest"; then echo "  fetched $(basename "$dest")"
  else echo "  WARN: failed to fetch $url"; rm -f "$dest"; fi
}

# ── plain theme files: "url|dest" ────────────────────────────────────
themes=(
  "https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme|$XDG_CONFIG/btop/themes/catppuccin_mocha.theme"
  "https://raw.githubusercontent.com/catppuccin/glamour/main/themes/catppuccin-mocha.json|$XDG_CONFIG/glow/catppuccin-mocha.json"
  "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme|$XDG_CONFIG/bat/themes/Catppuccin Mocha.tmtheme"
)
for entry in "${themes[@]}"; do fetch "${entry%%|*}" "${entry#*|}"; done

# ── bat: rebuild theme cache so `--theme` resolves (delta reuses it) ──
command -v bat >/dev/null 2>&1 && bat cache --build >/dev/null 2>&1 || true

# ── yazi flavor (git clone the single flavor dir; mise doesn't shim `ya`) ─────
if [ ! -d "$XDG_CONFIG/yazi/flavors/catppuccin-mocha.yazi" ]; then
  _tmp="$(mktemp -d)"
  if git clone --depth=1 -q https://github.com/yazi-rs/flavors "$_tmp" 2>/dev/null; then
    mkdir -p "$XDG_CONFIG/yazi/flavors"
    cp -r "$_tmp/catppuccin-mocha.yazi" "$XDG_CONFIG/yazi/flavors/" \
      && echo "  installed yazi catppuccin-mocha flavor"
  else
    echo "  WARN: yazi flavor clone failed"
  fi
  rm -rf "$_tmp"
fi

echo "Catppuccin themes ready."
