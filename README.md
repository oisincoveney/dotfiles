# Oisin's dotfiles

mise-managed shell, git, editor, and terminal config for macOS and Ubuntu.
`config.toml` is the whole machine: tools, Homebrew/App Store packages, git repos,
dotfiles, and the persistent-tmux unit.

## Install

```sh
mise bootstrap --adopt oisincoveney/dotfiles
```

That clones this repository into `~/.config/mise`, then applies it. On a machine
without mise, install the binary first:

```sh
curl -fsSL https://mise.run | sh
```

A brand-new host needs two `mise bootstrap` runs. The first clones `~/dev/agent`
(the agent harness repo, `[bootstrap.repos]`); the second sees it as mise's system
config — `.zshenv` exports `MISE_SYSTEM_CONFIG_FILE` — and installs the harness
from that repo's own `[dotfiles]` table.

## What is managed

- `zsh`, with the modules in `~/.config/zsh` and zinit for plugins
- Git config, global ignores, and global Git hook wrappers
- Homebrew formulae, casks, fonts, and Mac App Store apps in `[bootstrap.packages]`
- Neovim, tmux, ghostty, yazi, lazygit, btop, bat, starship, and the Catppuccin themes
- The persistent tmux systemd user unit on Linux

## Layout

| Path | Contents |
| --- | --- |
| `config.toml` | `~/.config/mise/config.toml` — tools, packages, repos, dotfiles, units |
| `mise.lock` | `~/.config/mise/mise.lock` — resolved versions and checksums |
| `home/` | `dotfiles.root`; every file maps to the same path under `$HOME` |
| `home/*.tera` | Rendered, not linked: `.gitconfig`, `.ssh/config` |

`home/` is applied with one `symlink-each` entry using `manifest = "git"`, so only
Git-tracked files are linked and unmanaged neighbours in a target directory survive.
Editing a deployed file edits this checkout.

## Local secrets

Do not commit tokens or machine-local credentials. Put local shell secrets in:

```sh
~/.config/zsh/secrets.zsh
```

`secret sync` regenerates that file from OpenBao; `.zshenv` sources it when it
exists, so non-interactive shells and agents get them too.

## mise

`~/.config/mise/config.toml` is a symlink to this repository's `config.toml`, so
normal global commands write straight back here:

```sh
mise use --global bat@latest
mise up
```

Commit the manifest or lockfile change normally. After pulling it on another host,
run `cza` (`mise bootstrap --yes`) to install the committed state.

## Useful commands

```sh
mise bootstrap --dry-run       # preview every phase
mise bootstrap status          # what is out of sync
mise dot diff                  # dotfile changes only
mise bootstrap packages status
```
