#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
INSTALL_PACKAGES=1

for arg in "$@"; do
  case "$arg" in
    --no-packages)
      INSTALL_PACKAGES=0
      ;;
    *)
      printf 'usage: %s [--no-packages]\n' "$0" >&2
      exit 2
      ;;
  esac
done

link_file() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf 'ok: %s already linked\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/"
    printf 'backup: %s -> %s/\n' "$target" "$BACKUP_DIR"
  fi

  ln -s "$source" "$target"
  printf 'link: %s -> %s\n' "$target" "$source"
}

install_packages_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  brew update
  brew bundle --file "$DOTFILES_DIR/Brewfile"
}

install_packages_ubuntu() {
  sudo apt update
  sudo apt install -y \
    curl \
    fd-find \
    fzf \
    gh \
    git \
    ripgrep \
    tmux \
    unzip \
    xclip \
    zoxide \
    zsh
}

install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
  fi
}

main() {
  if [[ "$INSTALL_PACKAGES" -eq 1 ]]; then
    case "$(uname -s)" in
      Darwin)
        install_packages_macos
        ;;
      Linux)
        if [[ -r /etc/os-release ]] && grep -qi ubuntu /etc/os-release; then
          install_packages_ubuntu
        else
          printf 'warn: package install is only scripted for macOS and Ubuntu\n' >&2
        fi
        ;;
    esac
  fi

  install_oh_my_zsh

  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
  link_file "$DOTFILES_DIR/git-hooks" "$HOME/.git-hooks"
  link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
  [[ "$(uname -s)" == "Darwin" ]] && link_file "$DOTFILES_DIR/.mackup.cfg" "$HOME/.mackup.cfg"

  mkdir -p "$HOME/.config/zsh" "$HOME/dev" "$HOME/projects"
  touch "$HOME/.config/zsh/secrets.zsh"

  if command -v zsh >/dev/null 2>&1 && [[ "$SHELL" != "$(command -v zsh)" ]]; then
    printf 'info: run this if you want zsh as your login shell: chsh -s "%s"\n' "$(command -v zsh)"
  fi
}

main "$@"
