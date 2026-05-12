# Oisin's dotfiles

Chezmoi-managed shell, git, editor, and terminal config for macOS and Ubuntu.

## Install

```sh
chezmoi init git@github.com:oisincoveney/dotfiles.git
chezmoi apply
```

On a machine without Chezmoi:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:oisincoveney/dotfiles.git
```

## What is managed

- `zsh` with Oh My Zsh
- shared aliases and PATH helpers in `~/.config/zsh`
- Git config, global ignores, and global Git hook wrappers
- package bootstrap scripts for macOS and Ubuntu
- Neovim, tmux, zellij, Codex, Claude, Gemini, and rulesync config

## Local secrets

Do not commit tokens or machine-local credentials. Put local shell secrets in:

```sh
~/.config/zsh/secrets.zsh
```

The main zsh config sources that file when it exists.

## Useful commands

```sh
chezmoi diff
chezmoi apply
chezmoi cd
```
