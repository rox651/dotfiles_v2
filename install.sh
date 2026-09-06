#!/usr/bin/env bash
# Bootstrap these dotfiles on macOS, Linux, or Windows (WSL / Git Bash).
# Native Windows without WSL: use install.ps1, then run this inside WSL.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(zsh git kitty nvim omp herdr)

cmd() { command -v "$1" >/dev/null 2>&1; }

os() {
  case "$(uname -s)" in
    Darwin) echo mac ;;
    Linux) echo linux ;;
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    *) echo unknown ;;
  esac
}

need_git() { cmd git || { echo "git is required"; exit 1; }; }

install_mac() {
  cmd brew || { echo "Install Homebrew first: https://brew.sh"; exit 1; }
  brew install git stow zsh neovim fzf zoxide lazygit nvm kitty fd ripgrep
}

install_linux() {
  if cmd apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y git stow zsh curl unzip neovim fd-find ripgrep fzf
  elif cmd dnf; then
    sudo dnf install -y git stow zsh curl unzip neovim fd-find ripgrep fzf
  elif cmd pacman; then
    sudo pacman -Sy --noconfirm git stow zsh curl unzip neovim fd ripgrep fzf
  else
    echo "Install git + stow + zsh + neovim yourself, then re-run."
    exit 1
  fi
  cmd lazygit || go_install_or_skip github.com/jesseduffield/lazygit@latest
  cmd zoxide || curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

go_install_or_skip() {
  if cmd go; then
    go install "$1"
  else
    echo "skip: $1 (no go). zinit/brew can cover this later."
  fi
}

install_nvm() {
  [ -s "$HOME/.nvm/nvm.sh" ] && return 0
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

install_cursor() {
  cmd agent && return 0
  cmd cursor-agent && return 0
  curl https://cursor.com/install -fsS | bash
}

install_herdr() {
  cmd herdr && return 0
  if cmd brew; then
    brew install herdr && return 0
  fi
  curl -fsSL https://herdr.dev/install.sh | sh
}

install_kiro() {
  cmd kiro-cli && return 0
  curl -fsSL https://cli.kiro.dev/install | bash
}

# 1=cursor 2=kiro 3=both 4=none  (or: cursor|kiro|both|none)
pick_clis() {
  local def=3 choice="${1:-}"
  [ "$(os)" = windows ] && def=1

  if [ -z "$choice" ] && [ -t 0 ]; then
    echo
    echo "Which agent CLIs?"
    echo "  1) Cursor"
    echo "  2) Kiro"
    echo "  3) Both"
    echo "  4) Neither"
    printf "Choice [%s]: " "$def"
    read -r choice
  fi
  [ -z "$choice" ] && choice="$def"

  CLI_CURSOR=0
  CLI_KIRO=0
  case "$choice" in
    1|cursor) CLI_CURSOR=1 ;;
    2|kiro) CLI_KIRO=1 ;;
    3|both) CLI_CURSOR=1; CLI_KIRO=1 ;;
    4|none|skip) ;;
    *) echo "unknown CLI choice: $choice (use 1-4, cursor, kiro, both, none)"; exit 1 ;;
  esac
}

# Real files block Stow. Move them aside so the repo copies can link.
backup_real() {
  local p="$1"
  [ -e "$p" ] || [ -L "$p" ] || return 0
  [ -L "$p" ] && return 0
  mkdir -p "$BACKUP/$(dirname "${p#"$HOME"/}")"
  mv "$p" "$BACKUP/${p#"$HOME"/}"
  echo "backed up $p -> $BACKUP/${p#"$HOME"/}"
}

stow_packages() {
  local adopt=0 pkgs=() extra=()
  for a in "$@"; do
    if [ "$a" = "--adopt" ]; then adopt=1; else pkgs+=("$a"); fi
  done
  [ ${#pkgs[@]} -eq 0 ] && pkgs=("${PACKAGES[@]}")

  cmd stow || { echo "stow not installed"; exit 1; }
  mkdir -p "$HOME/.config" "$HOME/.local/bin"

  if [ "$adopt" -eq 0 ]; then
    BACKUP="${BACKUP:-$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)}"
    backup_real "$HOME/.zshrc"
    backup_real "$HOME/.zshenv"
    backup_real "$HOME/.gitconfig"
    backup_real "$HOME/.config/nvim"
    backup_real "$HOME/.config/kitty/kitty.conf"
    backup_real "$HOME/.config/kitty/current-theme.conf"
    backup_real "$HOME/.config/herdr/kitty-attach.sh"
    backup_real "$HOME/.config/oh-my-posh"
  else
    extra+=(--adopt)
  fi

  local pkg
  for pkg in "${pkgs[@]}"; do
    (cd "$DOTFILES" && stow -v -t "$HOME" "${extra[@]}" "$pkg")
  done
}

usage() {
  cat <<EOF
usage: $0 [install|stow|adopt|unstow|dry-run] [--cli cursor|kiro|both|none]
  install   packages + CLIs + stow (default)
  stow      symlink packages into \$HOME
  adopt     stow --adopt (moves conflicts into this repo — commit first)
  unstow    remove symlinks
  dry-run   show stow actions
  --cli     skip the prompt (mac/linux default: both; windows: cursor)
EOF
}

main() {
  local action=install cli="" kind
  kind="$(os)"
  while [ $# -gt 0 ]; do
    case "$1" in
      --cli) cli="${2:-}"; shift 2 ;;
      -h|--help|help) usage; exit 0 ;;
      install|stow|adopt|unstow|dry-run) action="$1"; shift ;;
      *) usage; exit 1 ;;
    esac
  done

  case "$action" in
    install)
      need_git
      pick_clis "$cli"
      case "$kind" in
        mac) install_mac ;;
        linux) install_linux ;;
        windows)
          echo "Git Bash cannot run zsh/kitty/stow cleanly. Use WSL and re-run, or install.ps1 for native Windows tools."
          exit 1
          ;;
        *) echo "unsupported OS: $(uname -s)"; exit 1 ;;
      esac
      install_nvm
      install_herdr
      [ "$CLI_CURSOR" = 1 ] && install_cursor
      [ "$CLI_KIRO" = 1 ] && install_kiro
      stow_packages "${PACKAGES[@]}"
      echo "done. open a new terminal or: exec zsh"
      echo "if this is still bash: chsh -s \"$(command -v zsh)\""
      ;;
    stow) stow_packages "${PACKAGES[@]}" ;;
    adopt) stow_packages --adopt "${PACKAGES[@]}" ;;
    unstow) (cd "$DOTFILES" && stow -D -t "$HOME" "${PACKAGES[@]}") ;;
    dry-run) (cd "$DOTFILES" && stow -n -v -t "$HOME" "${PACKAGES[@]}") ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
