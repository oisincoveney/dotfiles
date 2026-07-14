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

## Mise

The human global manifest and merged lockfile are tracked under `.mise-global/`.
Chezmoi exposes them as `~/.config/mise/config.toml` and `~/.config/mise/mise.lock`
symlinks. The agent manifest is installed as mise's lower-precedence system config,
so normal global commands write directly back to this repository:

```sh
mise use --global bat@latest
mise up
```

Commit those manifest or lockfile changes normally. After pulling them on another
host, run `cza` to refresh the agent manifest and install the committed tool state.

## Useful commands

```sh
chezmoi diff
chezmoi apply
chezmoi cd
```
