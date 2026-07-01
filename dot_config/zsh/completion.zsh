# Completion init + styling. Runs after plugins.zsh (so zsh-completions is on
# fpath) and before tools.zsh (so `compdef` exists for atuin/zoxide/mise inits).

# compinit, cached: rebuild + security-audit the dump at most once a day; on warm
# days use -C to skip the audit (the slow part). Single compinit for the shell.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"
if [[ -n ${_zcompdump}(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
# Compile the dump so subsequent shells load it as bytecode.
if [[ -s "$_zcompdump" && ( ! -s "${_zcompdump}.zwc" || "$_zcompdump" -nt "${_zcompdump}.zwc" ) ]]; then
  zcompile "$_zcompdump"
fi
unset _zcompdump

# The zstyles below are read whenever the completion system runs.

# Case-insensitive, partial-word, and substring matching.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Group results by type with a coloured header; colour matches (LS_COLORS).
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}%B%d%b%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Cache slow completions (e.g. apt, brew).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Hand the menu to fzf-tab instead of zsh's built-in menu.
zstyle ':completion:*' menu no

# fzf-tab: catppuccin-consistent previews and a group switcher.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza -1 --color=always --icons=always $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview \
  'eza -1 --color=always --icons=always $realpath 2>/dev/null || ls -1 $realpath'
