# Oisin's dotfiles

mise-managed shell, git, editor, and terminal config for macOS and Ubuntu.
`config.toml` is the whole machine: tools, Homebrew/App Store packages, git repos,
dotfiles, and the persistent-tmux unit.

## Install

On a machine without mise, install the binary first and put it on `PATH`. Adopting
the repository needs `git` before the first run installs it; stock Ubuntu lacks it:

```sh
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
sudo apt-get install -y git      # Debian/Ubuntu; macOS ships git
```

Then adopt and apply this repository. `--force-dotfiles` replaces the distribution's
stock `~/.profile`, which otherwise blocks the first apply:

```sh
mise bootstrap --adopt oisincoveney/dotfiles --yes --force-dotfiles
```

That clones this repository into `~/.config/mise`, then applies it. The first run
also clones `~/dev/agent` (the agent harness, `[bootstrap.repos]`) over SSH, so the
host needs a GitHub key with access to `oisin-ee/agent`. The first run also installs
`gh`.

A brand-new host needs a second run from a new login shell. That shell sources
`.zshenv`, which exports `MISE_SYSTEM_CONFIG_FILE`, so mise loads the agent
repository as its system config and installs the harness from its `[dotfiles]`:

```sh
exec zsh -l
gh auth login          # mise resolves ~100 GitHub releases; anonymous API access allows 60/h
secret sync            # writes BROKER_API_KEY; the harness bootstrap needs it
exec zsh -l            # reload so .zshenv sources the new secrets file
mise bootstrap --yes   # the `cza` alias in an interactive shell
```

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
| `mise.lock` | Host-local, ignored — resolved versions and checksums for this machine |
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
mise use --global gwq@latest
```

Commit and push that change. `cza` (`mise bootstrap --yes`) then does three things:

1. Fast-forwards this checkout and `~/dev/agent`. Either one with uncommitted
   changes stops the run, so a local `mise use -g` is never left behind or overwritten.
2. Installs missing tools, packages, and dotfiles.
3. Upgrades every `latest` tool to its newest release at least 24 hours old
   (mise's `minimum_release_age`), from this repository and the agent repository.

## Useful commands

```sh
mise bootstrap --dry-run       # preview every phase
mise bootstrap status          # what is out of sync
mise dot diff                  # dotfile changes only
mise bootstrap packages status
```
