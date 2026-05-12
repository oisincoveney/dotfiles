# Add directories to PATH without duplicating entries on shell reload.
add_to_path() {
  [[ -d "$1" ]] || return
  [[ ":$PATH:" == *":$1:"* ]] && return
  export PATH="$1:$PATH"
}

append_to_path() {
  [[ -d "$1" ]] || return
  [[ ":$PATH:" == *":$1:"* ]] && return
  export PATH="$PATH:$1"
}

add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.bun/bin"
add_to_path "$DOTFILES/bin"
add_to_path "$HOME/.node/bin"
add_to_path "$HOME/.android-dev"

# App-specific CLIs. These are harmless when the apps are not installed.
add_to_path "$HOME/.codeium/windsurf/bin"
add_to_path "$HOME/.antigravity/antigravity/bin"
append_to_path "$HOME/.lmstudio/bin"

# Project-local binaries.
add_to_path "vendor/bin"
add_to_path "node_modules/.bin"
