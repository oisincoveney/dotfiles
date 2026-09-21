# Shell history. atuin (loaded in tools.zsh) owns interactive search, but the
# plain-file history is still written so atuin can import it and so history
# works on machines where atuin is absent.

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY       # record timestamp + duration per command
setopt SHARE_HISTORY          # share history live across open shells
setopt INC_APPEND_HISTORY     # append as typed, not only on exit
setopt HIST_IGNORE_DUPS       # don't record a line identical to the previous
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicates of a re-entered command
setopt HIST_IGNORE_SPACE      # a leading space keeps a command out of history
setopt HIST_SAVE_NO_DUPS      # never write duplicate entries to the file
setopt HIST_REDUCE_BLANKS     # trim superfluous whitespace
setopt HIST_VERIFY            # expand a !history reference onto the line first
