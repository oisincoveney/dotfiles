# Plugins via zinit. Bootstrap snippet per the zinit README:
#   https://github.com/zdharma-continuum/zinit
# Split load:
#  - zsh-completions is loaded synchronously (blockf = fpath-only, cheap) so the
#    compinit run in completion.zsh — which follows this file — sees it, and so
#    `compdef` exists before the tool inits in tools.zsh call it.
#  - The interactive widgets (fzf-tab, autosuggestions, syntax-highlighting) are
#    turbo-deferred past the first prompt. Order per the fzf-tab README: fzf-tab
#    after compinit, before the widget-wrapping plugins; syntax-highlighting last.

# --- bootstrap: clone zinit on first run, no framework required ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  command -v git >/dev/null 2>&1 || return
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" 2>/dev/null
fi
source "$ZINIT_HOME/zinit.zsh"

# --- extra completions on fpath now (cheap), for the upcoming compinit ---
zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

# --- plugin cosmetics (read when the deferred plugins load) ---
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'   # catppuccin mocha: overlay0

# --- turbo block: interactive widgets, loaded after the prompt appears ---
zinit wait lucid for \
    Aloxaf/fzf-tab \
    atload'_zsh_autosuggest_start; (( $+functions[_zsh_keybindings_install_completion_keys] )) && _zsh_keybindings_install_completion_keys' \
      zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting \
    olets/zsh-abbr
