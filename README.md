# Oisin's dotfiles

Personal shell, git, and terminal tooling for macOS and Ubuntu.

## What is managed

- `zsh` via Oh My Zsh
- `aliases.zsh` and `path.zsh`
- Git defaults and global ignore rules
- Global Git hook wrappers for Lefthook and Beads
- `tmux` defaults
- Homebrew packages for macOS
- Ubuntu shell package bootstrap

Machine-local secrets and one-off environment variables belong in:

```sh
~/.config/zsh/secrets.zsh
```

That file is created by the installer and must not be committed.

## Install

Clone the repo:

```sh
git clone --recursive git@github.com:oisincoveney/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

To only link files without installing packages:

```sh
./install.sh --no-packages
```

For a fresh Mac, use:

```sh
cd ~/.dotfiles
./fresh.sh
```

`install.sh` backs up existing files to `~/.dotfiles-backup/<timestamp>/` before linking managed files.

## Ubuntu notes

The Ubuntu path installs the shell tools this setup expects:

```sh
sudo apt update
sudo apt install -y curl fd-find fzf gh git ripgrep tmux unzip xclip zoxide zsh
```

Some tools are optional and only initialize when installed:

- `oh-my-posh`
- `mise`
- `moon`
- `wtp`
- `gcloud`
- `openclaw`
- `claude`
- `codex`

Install those per machine only when needed.

## macOS notes

macOS packages are managed by `Brewfile`:

```sh
brew bundle --file ~/.dotfiles/Brewfile
```

macOS defaults live in `.macos` and are only applied by `fresh.sh`.

## Updating

After changing local shell config, update the repo instead of editing only `~` files:

```sh
cd ~/.dotfiles
git status
git add .
git commit -m "Update dotfiles"
git push
```
