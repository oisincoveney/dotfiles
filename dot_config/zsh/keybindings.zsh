# Key bindings. Emacs mode plus sane Delete/Backspace/Home/End across terminals
# and partial-terminfo SSH sessions. Kept after plugin/fzf load in the loader so
# widget-wrapping plugins don't clobber these.

bindkey -e   # emacs keymap

bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char
bindkey '^[3;5~' delete-char

[[ -n "${terminfo[kdch1]:-}" ]] && bindkey "${terminfo[kdch1]}" delete-char
[[ -n "${terminfo[khome]:-}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]:-}"  ]] && bindkey "${terminfo[kend]}"  end-of-line

# Word-wise navigation with Alt/Option + arrows.
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
