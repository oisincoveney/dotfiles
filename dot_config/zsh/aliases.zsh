# Modern CLI replacements (guarded — fall back to coreutils when absent).
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto --group-directories-first'
  alias l='eza -l --icons=auto --group-directories-first --git'
  alias ll='eza -lah --icons=auto --group-directories-first --git'
  alias la='eza -a --icons=auto --group-directories-first'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
fi
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# Shortcuts
alias reloadshell="exec zsh"
alias compile="commit 'compile'"
alias timestamp="date +%s"
alias version="commit 'version'"

shrug() {
  local text='¯\_(ツ)_/¯'

  if command -v pbcopy >/dev/null 2>&1; then
    print -rn -- "$text" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    print -rn -- "$text" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    print -rn -- "$text" | xclip -selection clipboard
  else
    print -r -- "$text"
  fi
}

# Directories
dotfiles() {
  cd "$DOTFILES" || return
}

library() {
  cd "$HOME/Library" || return
}

projects() {
  if [[ -d "$HOME/dev" ]]; then
    cd "$HOME/dev" || return
  elif [[ -d "$HOME/Code" ]]; then
    cd "$HOME/Code" || return
  else
    cd "$HOME/projects" || return
  fi
}

# Git
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias diff="git diff"
alias force="git push --force-with-lease"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias prune="git fetch --prune"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit wip"

# Agents
alias cc="CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions"
alias co="codex --dangerously-bypass-approvals-and-sandbox"
alias ki="kimi --yolo"
alias oc="opencode --dangerously-skip-permissions"
