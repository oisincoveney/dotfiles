if [[ "$(uname -s)" == "Darwin" ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
fi
