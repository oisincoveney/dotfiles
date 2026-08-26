# Plugins via zinit. Bootstrap snippet per the zinit README:
#   https://github.com/zdharma-continuum/zinit
# Split load:
#  - zsh-completions is loaded synchronously (blockf = fpath-only, cheap) so the
#    compinit run in completion.zsh — which follows this file — sees it, and so
#    `compdef` exists before the tool inits in tools.zsh call it.
#  - fast-syntax-highlighting and zsh-abbr are turbo-deferred past the first
#    prompt so they never block startup.

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

# --- turbo block: interactive widgets, loaded after the prompt appears ---
zinit wait lucid for \
    zdharma-continuum/fast-syntax-highlighting \
    olets/zsh-abbr