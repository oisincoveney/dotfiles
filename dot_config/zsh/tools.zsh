# Modern CLI tool integrations + the catppuccin-mocha theming that ties the
# terminal together. Two data-driven loaders own the repetitive shapes; only the
# genuinely-unique integrations (fzf, atuin, terminal-specific) are spelled out.

# ── theme: catppuccin mocha, single source for fzf / bat / eza colours ────────
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a,border:#585b70,label:#cdd6f4 \
--height 60% --layout reverse --border rounded --info inline-right"
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'
export BAT_THEME='Catppuccin Mocha'

# ── cached tool init: fork the binary once, cache its shell output, re-source ──
# `eval "$(starship init zsh)"` forks a process every startup. Caching the output
# and regenerating only when the binary is newer turns N forks into zero on warm
# starts — the single biggest startup win here.
_evalcache() {
  local bin="$1"
  command -v "$bin" >/dev/null 2>&1 || return 0
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/evalcache/${bin}.zsh"
  if [[ ! -s "$cache" || "$(command -v -- "$bin")" -nt "$cache" ]]; then
    mkdir -p "${cache:h}"
    if ! "$@" >| "$cache" 2>/dev/null; then
      rm -f "$cache"
      "$@" 2>/dev/null | source /dev/stdin   # binary can't cache: run live
      return 0
    fi
  fi
  source "$cache"
}

# One concept ("activate shell integration if the binary exists, cached") owns
# this axis, instead of a stack of near-identical `if command -v X` blocks.
_evalcache starship init zsh
_evalcache zoxide init zsh
_evalcache mise activate zsh
_evalcache wtp shell-init zsh

# ── helper: source the first readable file from a candidate list (SDKs) ───────
_source_first() {
  local f
  for f in "$@"; do
    [[ -r "$f" ]] && { source "$f"; return 0; }
  done
  return 1
}

# Google Cloud SDK PATH — needed eagerly so the `gcloud` binary resolves.
_source_first /opt/homebrew/share/google-cloud-sdk/path.zsh.inc \
              "$HOME/google-cloud-sdk/path.zsh.inc"

# ── defer heavy completions to just after the first prompt ────────────────────
# gcloud's completion.inc fires compinit + ~1000 compdefs (~300ms). Running it on
# the first precmd keeps time-to-prompt low — the shell is usable instantly and
# completions arrive a beat later. Runs once.
autoload -Uz add-zsh-hook
_load_deferred_completions() {
  _source_first /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc \
                "$HOME/google-cloud-sdk/completion.zsh.inc"
  add-zsh-hook -d precmd _load_deferred_completions
  unset -f _load_deferred_completions
}
add-zsh-hook precmd _load_deferred_completions

# ── unique integrations that don't fit the table ─────────────────────────────

# fzf key-bindings + completion: only in a real interactive TTY.
if [[ -o interactive && -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  if [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    # Debian/Ubuntu package layout (older fzf without `--zsh`).
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
  else
    _evalcache fzf --zsh   # fzf >= 0.48
  fi
fi

# atuin LAST: it rebinds Ctrl-R / Up, so it must win over fzf's bindings.
# --disable-up-arrow keeps the Up key as plain previous-line history. Cached.
_evalcache atuin init zsh --disable-up-arrow

# moka: refresh the global agent harness (~/.claude, ~/.config/opencode, ~/.codex)
# only when the moka package version changes. The whole check is forked and
# disowned (&!), so it never blocks the prompt — startup pays nothing.
if command -v moka >/dev/null 2>&1; then
  {
    _moka_vf="${XDG_STATE_HOME:-$HOME/.local/state}/moka-harness-version"
    _moka_cur="$(moka --version 2>/dev/null)"
    if [[ -n "$_moka_cur" && "$_moka_cur" != "$(cat "$_moka_vf" 2>/dev/null)" ]]; then
      moka init --force >/dev/null 2>&1 && { mkdir -p "${_moka_vf:h}"; print -r -- "$_moka_cur" >| "$_moka_vf"; }
    fi
  } &!
fi
