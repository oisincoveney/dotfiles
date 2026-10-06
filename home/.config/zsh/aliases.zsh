# Modern CLI replacements (guarded — fall back to coreutils when absent).
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto --group-directories-first'
  alias l='eza -l --icons=auto --group-directories-first --git'
  alias ll='eza -lah --icons=auto --group-directories-first --git'
  alias la='eza -la --icons=auto --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
fi
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
# Zen kit — interactive-only aliases (never affect scripts). Each guarded.
command -v dust >/dev/null 2>&1        && alias du='dust'
command -v duf >/dev/null 2>&1         && alias df='duf'
command -v procs >/dev/null 2>&1       && alias ps='procs'
command -v btop >/dev/null 2>&1        && { alias top='btop'; alias htop='btop'; }
command -v xh >/dev/null 2>&1          && alias http='xh'
command -v doggo >/dev/null 2>&1       && alias dig='doggo'
command -v glow >/dev/null 2>&1        && alias md='glow'
command -v lazygit >/dev/null 2>&1     && alias lg='lazygit'
command -v lazydocker >/dev/null 2>&1  && alias lzd='lazydocker'
command -v onefetch >/dev/null 2>&1    && alias ofetch='onefetch'
command -v jless >/dev/null 2>&1       && alias jl='jless'

# Agent kit — short handles for the new tools (git dft handled in gitconfig).
command -v difft >/dev/null 2>&1       && alias dft='difft'
command -v k9s >/dev/null 2>&1         && alias k9='k9s'
command -v just >/dev/null 2>&1        && alias j='just'
command -v kubectx >/dev/null 2>&1     && alias kx='kubectx'
command -v kubens >/dev/null 2>&1      && alias kn='kubens'
# Project scripts — `nr` runs the named package.json script, `mt` lists
# mise tasks. Lightweight, on-demand; no per-prompt enumeration.
command -v npm >/dev/null 2>&1         && alias nr='npm run'
command -v mise >/dev/null 2>&1        && alias mt='mise tasks'
# kubecolor: colorized kubectl. Alias only when kubectl exists; forward its
# completions (guarded — compdef exists only after compinit has run).
if command -v kubecolor >/dev/null 2>&1 && command -v kubectl >/dev/null 2>&1; then
  alias kubectl='kubecolor'
  (( $+functions[compdef] )) && compdef kubecolor=kubectl
fi

# Shortcuts
# `mise bootstrap` is the whole installer: repos (this checkout and ~/dev/agent,
# fast-forwarded, refused while dirty), packages, dotfiles, units, tools upgraded
# to latest, and the agent harness. A missing BROKER_API_KEY aborts the run
# before any mutation.
alias cza="mise bootstrap --yes"
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

# Parent navigation — `..` (one up) is built into zsh; add `...` for two up.
alias ...='cd ../..'

# Worktree manager (Worktrunk). `wt config shell init zsh` in tools.zsh wires
# the in-shell `wt switch` behavior.
if command -v wt >/dev/null 2>&1; then
  alias gwl='wt list'
  alias gwc='wt switch'
  alias gwr='wt remove'
fi

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
# These run their agent with sandbox/approvals OFF. To opt INTO a sandbox for a
# single run (not wired in by default — it's a deliberate behaviour change):
#   • srt "<cmd>"         — OS-level fs/net sandbox (srt, @anthropic-ai/sandbox-runtime);
#                           e.g. `srt "claude --dangerously-skip-permissions"`, restrictions in ~/.srt-settings.json
#   • container-use / cu  — run the agent inside a disposable dagger dev container
#   • nono <cmd>          — capability-based sandbox shell (mac; profile-driven)
#
# Agents start through `momo-agent`: in oisin-ee repositories an agent acts as the
# momo-momokaya[bot] App, and in every other repository as your personal login.
# Your own shells always use the personal login. `herdr agent start` types the
# bare agent name at the prompt, so the plain names are wrapped too. `cza`
# installs the App key (see ~/dev/agent/docs/agent-identity.md).
if (( $+commands[momo-agent] )); then
  _momo="momo-agent "
  alias claude="momo-agent claude" codex="momo-agent codex" pi="momo-agent pi"
fi
alias cc="${_momo}env CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions"
alias co="${_momo}codex --dangerously-bypass-approvals-and-sandbox"
unset _momo
alias ki="kimi --yolo"
