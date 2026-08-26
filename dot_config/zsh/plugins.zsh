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
#
# zsh-history-substring-search: Up/Down walk only the history entries that
# contain what is already typed. Native `up-line-or-beginning-search` does
# PREFIX matching; this does SUBSTRING, so typing `tar` also reaches
# `git tarball --list`. See docs/zsh-research.md.
#
# The Up arrow is free: tools.zsh runs `atuin init zsh --disable-up-arrow`,
# which suppresses exactly atuin's seven up-arrow bindings and leaves Ctrl-R
# alone. Both `^[[A` and `^[OA` are bound because terminals emit the latter
# in application cursor mode (atuin itself binds both).
#
# Keys are bound via atload' ' so they land after the deferred load.
zinit wait lucid for \
    zdharma-continuum/fast-syntax-highlighting \
    olets/zsh-abbr \
    atload'
      HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
      bindkey -M emacs "^[[A" history-substring-search-up
      bindkey -M emacs "^[[B" history-substring-search-down
      bindkey -M emacs "^[OA" history-substring-search-up
      bindkey -M emacs "^[OB" history-substring-search-down
      bindkey -M viins "^[[A" history-substring-search-up
      bindkey -M viins "^[[B" history-substring-search-down
    ' zsh-users/zsh-history-substring-search