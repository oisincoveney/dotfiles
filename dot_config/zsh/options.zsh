# Interactive shell options. Behavioural knobs only — no output, no PATH.

# Directories
setopt AUTO_CD              # `foo` == `cd foo` when foo is a dir
setopt AUTO_PUSHD          # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS   # no duplicate entries on the stack
setopt PUSHD_SILENT        # don't print the stack after pushd/popd

# Globbing
setopt EXTENDED_GLOB       # #, ~, ^ operators in globs
setopt GLOB_DOTS           # match dotfiles without a leading-dot in the pattern
setopt NUMERIC_GLOB_SORT   # sort numeric filenames numerically

# Word boundaries: only alphanumerics are word chars, so backward-kill-word
# stops at / . - _ etc. (restores oh-my-zsh behavior)
WORDCHARS=''

# Misc quality-of-life
setopt INTERACTIVE_COMMENTS  # allow `# comments` at the prompt
setopt COMPLETE_IN_WORD      # complete from both ends of the cursor
setopt ALWAYS_TO_END         # move cursor to end after completion
unsetopt BEEP                # no terminal bell
unsetopt CORRECT             # no "did you mean" autocorrect
