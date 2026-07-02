# Key bindings. Emacs mode plus sane Delete/Backspace/Home/End across terminals
# and partial-terminfo SSH sessions. Kept after plugin/fzf load in the loader so
# widget-wrapping plugins don't clobber these.

bindkey -e   # emacs keymap

bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char
bindkey '^[[3;5~' delete-char

[[ -n "${terminfo[kdch1]:-}" ]] && bindkey "${terminfo[kdch1]}" delete-char
[[ -n "${terminfo[khome]:-}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]:-}"  ]] && bindkey "${terminfo[kend]}"  end-of-line

# Word-wise navigation with Alt/Option + arrows.
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

_tab_accept_autosuggestion_fallback() {
  return 0
}
(( ${+widgets[tab-accept-autosuggestion]} )) || zle -N tab-accept-autosuggestion _tab_accept_autosuggestion_fallback

# Defining this before zsh-autosuggestions loads means we must also keep its
# defaults; otherwise its config sees the array already set and skips them.
typeset -Uga ZSH_AUTOSUGGEST_ACCEPT_WIDGETS
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
  forward-char
  end-of-line
  vi-forward-char
  vi-end-of-line
  vi-add-eol
  ${ZSH_AUTOSUGGEST_ACCEPT_WIDGETS[@]}
  tab-accept-autosuggestion
)

typeset -ga _ZSH_SHORTCUT_ROWS
_ZSH_SHORTCUT_ROWS=(
  $'Scope\tKey\tAction\tSource'
  $'Completion\tTab\tAccept visible autosuggestion\tzsh-autosuggestions'
  $'Completion\tShift-Tab\tOpen completion picker\tfzf-tab'
  $'Picker\tCtrl-T\tOpen command-aware file/folder picker\ttelevision'
  $'Search\tCtrl-R\tSearch shell history\tatuin'
  $'Search\tCtrl-G\tOpen cheatsheet picker\tnavi'
  $'Navigation\tAlt-Left / Alt-Right\tMove one word\tzsh'
  $'Navigation\tCtrl-A / Ctrl-E\tGo to start/end of line\tzsh'
  $'Navigation\tCtrl-P / Ctrl-N\tPrevious/next history item\tzsh'
  $'Editing\tCtrl-W / Alt-D\tKill previous/next word\tzsh'
  $'Editing\tCtrl-U / Ctrl-K\tKill before/after cursor\tzsh'
  $'Editing\tCtrl-Y\tYank killed text\tzsh'
  $'Editing\tCtrl-L\tClear screen\tzsh'
  $'Editing\tDelete / Backspace\tDelete forward/backward\tzsh'
  $'Help\tshortcuts\tShow searchable shortcut helper\tdotfiles'
  $'Help\tshortcuts --print\tPrint shortcut table\tdotfiles'
  $'Help\tshortcuts --raw\tPrint table plus live bindkey map\tdotfiles'
)

_zsh_shortcut_rows() {
  print -r -l -- "${_ZSH_SHORTCUT_ROWS[@]}"
}

_zsh_print_shortcuts() {
  if command -v column >/dev/null 2>&1; then
    _zsh_shortcut_rows | column -t -s $'\t'
  else
    _zsh_shortcut_rows
  fi
}

shortcuts() {
  emulate -L zsh

  case "${1:-}" in
    "" )
      if [[ -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
        _zsh_print_shortcuts | fzf --height=70% --layout=reverse --border \
          --header-lines=1 \
          --prompt='shortcuts> ' \
          --header='Type to filter. Enter closes.'
      else
        _zsh_print_shortcuts
      fi
      ;;
    --print|-p )
      _zsh_print_shortcuts
      ;;
    --raw|-r )
      _zsh_print_shortcuts
      print
      print -r -- 'Live emacs keymap:'
      bindkey -M emacs
      ;;
    --help|-h )
      print -r -- 'Usage: shortcuts [--print|--raw]'
      ;;
    * )
      print -u2 -r -- "shortcuts: unknown option: $1"
      return 2
      ;;
  esac
}

_zsh_keybindings_install_completion_keys() {
  emulate -L zsh

  if (( ${+functions[_zsh_autosuggest_bind_widget]} )) \
    && [[ ${widgets[tab-accept-autosuggestion]-} != user:_zsh_autosuggest_bound_* ]]; then
    _zsh_autosuggest_bind_widget tab-accept-autosuggestion accept
  fi

  if [[ ${widgets[tab-accept-autosuggestion]-} == user:_zsh_autosuggest_bound_* ]]; then
    bindkey -M emacs '^I' tab-accept-autosuggestion
    bindkey -M viins '^I' tab-accept-autosuggestion
  fi

  if (( ${+widgets[fzf-tab-complete]} )); then
    typeset -Ua shift_tab_keys
    shift_tab_keys=($'\e[Z')
    [[ -n "${terminfo[kcbt]:-}" ]] && shift_tab_keys+=("${terminfo[kcbt]}")

    local key
    for key in "${shift_tab_keys[@]}"; do
      bindkey -M emacs "$key" fzf-tab-complete
      bindkey -M viins "$key" fzf-tab-complete
    done
  fi

  if [[ ${widgets[tab-accept-autosuggestion]-} == user:_zsh_autosuggest_bound_* ]] \
    && (( ${+widgets[fzf-tab-complete]} )); then
    add-zsh-hook -d precmd _zsh_keybindings_install_completion_keys
    add-zle-hook-widget -d line-init _zsh_keybindings_install_completion_keys
  fi
}

autoload -Uz add-zsh-hook add-zle-hook-widget
add-zsh-hook precmd _zsh_keybindings_install_completion_keys
add-zle-hook-widget line-init _zsh_keybindings_install_completion_keys
