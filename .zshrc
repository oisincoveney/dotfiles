# Dotfiles
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$DOTFILES}"

ZSH_THEME="${ZSH_THEME:-random}"
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="true"
HIST_STAMPS="yyyy-mm-dd"
plugins=(git)

if [[ -d "$ZSH_CUSTOM/completions" ]]; then
  fpath=("$ZSH_CUSTOM/completions" $fpath)
fi

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
  [[ -r "$DOTFILES/path.zsh" ]] && source "$DOTFILES/path.zsh"
  [[ -r "$DOTFILES/aliases.zsh" ]] && source "$DOTFILES/aliases.zsh"
fi

# Locale
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"

# Smart cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Fuzzy finder
if [[ -o interactive && -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# Prompt
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config catppuccin)"
fi

# Runtime/tool managers
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -r "$HOME/.moon/bin/env" ]]; then
  source "$HOME/.moon/bin/env"
fi

# Optional tool integrations
if command -v wtp >/dev/null 2>&1; then
  eval "$(wtp shell-init zsh)"
fi

if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null 2>&1; then
  source "$(kiro --locate-shell-integration-path zsh)"
fi

if command -v openclaw >/dev/null 2>&1; then
  source <(openclaw completion --shell zsh)
fi

# Google Cloud SDK completions: Homebrew on macOS, direct install on Linux.
if [[ -r /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ]]; then
  source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
fi

if [[ -r /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ]]; then
  source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
fi

if [[ -r "$HOME/google-cloud-sdk/path.zsh.inc" ]]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi

if [[ -r "$HOME/google-cloud-sdk/completion.zsh.inc" ]]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# AsyncAPI CLI autocomplete
ASYNCAPI_AC_ZSH_SETUP_PATH="$HOME/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup"
if [[ -r "$ASYNCAPI_AC_ZSH_SETUP_PATH" ]]; then
  source "$ASYNCAPI_AC_ZSH_SETUP_PATH"
fi
unset ASYNCAPI_AC_ZSH_SETUP_PATH

# Machine-local env vars, tokens, and one-off overrides. Do not commit this file.
if [[ -r "$HOME/.config/zsh/secrets.zsh" ]]; then
  source "$HOME/.config/zsh/secrets.zsh"
fi
