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

# Tab. On an empty line, offer directories to cd into and let repeated Tab
# cycle through them; anywhere else, complete normally.
#
# A widget is required. On an empty line zsh completes a COMMAND, dispatched
# to _autocd, and Completion/Zsh/Command/_cd (lines 106-110) deliberately
# refuses to offer local directories in command position. No zstyle changes
# that.
#
# `zle menu-complete` must NOT be written `zle .menu-complete`. compinit
# redefines the undotted name as `zle -C menu-complete .menu-complete
# _main_complete`, i.e. the modern completion system; the dotted name is the
# raw builtin driving the obsolete compctl system, which has no rules here
# and so silently does nothing. See docs/zsh-research.md.
zmodload -i zsh/zle 2>/dev/null
zmodload -i zsh/complist 2>/dev/null
setopt ALWAYS_LAST_PROMPT   # menu selection needs it (zsh manual 22.7.3)

_empty_tab_cd() {
  if [[ -z ${BUFFER//[[:space:]]/} ]]; then
    BUFFER='cd '
    CURSOR=$#BUFFER
    zle menu-complete
  else
    zle expand-or-complete
  fi
}
zle -N _empty_tab_cd
bindkey -M emacs '^I' _empty_tab_cd
bindkey -M viins '^I' _empty_tab_cd

# Inside the completion menu: Tab/Shift-Tab step, Escape leaves.
bindkey -M menuselect '^I'   menu-complete
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey -M menuselect '^['   send-break

# The zstyles below are read whenever the completion system runs.

# Case-insensitive, partial-word, and substring matching.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Arrow-key/Tab selection in the completion list. Do NOT add
# `special-dirs true` here: it inserts ./ and ../ as candidates, ./ sorts
# first, and the first Tab on an empty line then yields a useless `cd ./`.
zstyle ':completion:*' menu select

# Group results by type with a coloured header; colour matches (LS_COLORS).
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}%B%d%b%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Cache slow completions (e.g. apt, brew).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
