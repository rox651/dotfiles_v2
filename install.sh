#!/usr/bin/env bash
# Bootstrap these dotfiles on macOS, Linux, or Windows (WSL / Git Bash).
# Native Windows without WSL: use install.ps1, then run this inside WSL.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(zsh git kitty nvim omp herdr)
MAC_PACKAGES=(aerospace sketchybar borders)

cmd() { command -v "$1" >/dev/null 2>&1; }

os() {
  case "$(uname -s)" in
  Darwin) echo mac ;;
  Linux) echo linux ;;
  MINGW* | MSYS* | CYGWIN*) echo windows ;;
  *) echo unknown ;;
  esac
}

# shellcheck source=agent.sh
. "$DOTFILES/agent.sh"

need_git() { cmd git || {
  echo "git is required"
  exit 1
}; }

install_mac() {
  cmd brew || {
    echo "Install Homebrew first: https://brew.sh"
    exit 1
  }
  brew install git stow zsh neovim fzf zoxide lazygit nvm kitty fd ripgrep
}

install_linux() {
  if cmd apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y git stow zsh curl unzip fd-find ripgrep
  elif cmd dnf; then
    sudo dnf install -y git stow zsh curl unzip fd-find ripgrep fzf
  elif cmd pacman; then
    sudo pacman -Sy --noconfirm git stow zsh curl unzip fd ripgrep fzf
  else
    echo "Install git + stow + zsh + neovim yourself, then re-run."
    exit 1
  fi
  cmd zoxide || curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

install_nvim() {
  export PATH="$HOME/.local/bin:$PATH"
  mkdir -p "$HOME/.local/bin"

  if [ "$(os)" = mac ]; then
    brew install neovim
    brew upgrade neovim || true
    return 0
  fi

  local arch tarball dir
  case "$(uname -m)" in
  x86_64 | amd64) arch=x86_64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *)
    echo "unknown arch for nvim: $(uname -m)"
    return 1
    ;;
  esac
  tarball="nvim-linux-${arch}.tar.gz"
  dir="nvim-linux-${arch}"

  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${tarball}" -o "$tmp/nvim.tar.gz"
  tar -C "$tmp" -xzf "$tmp/nvim.tar.gz"
  rm -rf "$HOME/.local/nvim"
  mv "$tmp/$dir" "$HOME/.local/nvim"
  ln -sfn "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"

  if cmd apt-get && dpkg -l neovim 2>/dev/null | grep -q '^ii'; then
    sudo apt-get remove -y neovim
  fi
}

load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  elif [ -s /opt/homebrew/opt/nvm/nvm.sh ]; then
    . /opt/homebrew/opt/nvm/nvm.sh
  fi
}

install_nvm() {
  load_nvm
  cmd nvm && return 0
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  load_nvm
}

install_node() {
  load_nvm
  nvm install --lts
  nvm alias default 'lts/*'
  if cmd corepack; then
    corepack enable
    corepack prepare yarn@stable --activate
    corepack prepare pnpm@latest --activate
  else
    npm install -g yarn pnpm
  fi
}

install_lazygit() {
  cmd lazygit && return 0
  mkdir -p "$HOME/.local/bin"
  if [ "$(os)" = mac ]; then
    brew install lazygit
    return 0
  fi
  local arch ver tmp
  case "$(uname -m)" in
  x86_64 | amd64) arch=Linux_x86_64 ;;
  aarch64 | arm64) arch=Linux_arm64 ;;
  *)
    echo "unknown arch for lazygit: $(uname -m)"
    return 1
    ;;
  esac
  ver="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -1)"
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_${arch}.tar.gz" -o "$tmp/lg.tgz"
  tar -C "$tmp" -xzf "$tmp/lg.tgz" lazygit
  install -m 755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
}

install_treesitter_cli() {
  load_nvm
  npm install -g tree-sitter-cli
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

link_herdr_default_tabs() {
  cmd herdr || return 0
  local dir="$HOME/.config/herdr/default-tabs"
  [ -f "$dir/herdr-plugin.toml" ] || return 0
  herdr plugin link "$dir"
}

install_mac_wm() {
  [ "$(os)" = mac ] || return 0
  cmd brew || return 0

  brew trust nikitabobko/tap 2>/dev/null || true
  brew trust --formula felixkratz/formulae/sketchybar 2>/dev/null || true
  brew trust --formula felixkratz/formulae/borders 2>/dev/null || true
  brew install --cask nikitabobko/tap/aerospace
  brew install felixkratz/formulae/sketchybar felixkratz/formulae/borders lua switchaudio-osx nowplaying-cli

  mkdir -p "$HOME/Library/Fonts"
  local font="$HOME/Library/Fonts/sketchybar-app-font.ttf"
  if [ ! -f "$font" ]; then
    curl -fsSL \
      https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.30/sketchybar-app-font.ttf \
      -o "$font"
  fi

  if [ ! -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]; then
    local tmp
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua"
    make -C "$tmp/SbarLua" install
    rm -rf "$tmp"
  fi
}

start_mac_wm() {
  [ "$(os)" = mac ] || return 0
  local cfg="$HOME/.config/sketchybar"
  if [ -d "$cfg/helpers" ]; then
    (cd "$cfg/helpers" && make)
  fi
  brew services start sketchybar 2>/dev/null || true
  brew services start borders 2>/dev/null || true
  open -a AeroSpace 2>/dev/null || true
}

stow_package_list() {
  local pkgs=("$@")
  if [ "$(os)" = mac ]; then
    pkgs+=("${MAC_PACKAGES[@]}")
  fi
  printf '%s\n' "${pkgs[@]}"
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
  1 | cursor) CLI_CURSOR=1 ;;
  2 | kiro) CLI_KIRO=1 ;;
  3 | both)
    CLI_CURSOR=1
    CLI_KIRO=1
    ;;
  4 | none | skip) ;;
  *)
    echo "unknown CLI choice: $choice (use 1-4, cursor, kiro, both, none)"
    exit 1
    ;;
  esac
}

# Real files block Stow. Never mv a path that already lives in this repo
# (Stow dir-fold makes ~/.config/herdr a symlink into ~/dotfiles).
in_dotfiles() {
  local p="$1" real
  [ -e "$p" ] || [ -L "$p" ] || return 1
  if [ -d "$p" ]; then
    real="$(cd "$p" && pwd -P)"
  else
    real="$(cd "$(dirname "$p")" && pwd -P)/$(basename "$p")"
  fi
  case "$real" in
  "$DOTFILES" | "$DOTFILES"/*) return 0 ;;
  esac
  return 1
}

backup_real() {
  local p="$1"
  [ -e "$p" ] || [ -L "$p" ] || return 0
  [ -L "$p" ] && return 0
  in_dotfiles "$p" && return 0
  mkdir -p "$BACKUP/$(dirname "${p#"$HOME"/}")"
  mv "$p" "$BACKUP/${p#"$HOME"/}"
  echo "backed up $p -> $BACKUP/${p#"$HOME"/}"
}

# Stow folds missing dirs into the package. Herdr then writes logs into git.
unfold_config() {
  local p="$1"
  if [ -L "$p" ] && in_dotfiles "$p"; then
    rm "$p"
  fi
  mkdir -p "$p"
}

stow_packages() {
  local adopt=0 pkgs=()
  for a in "$@"; do
    if [ "$a" = "--adopt" ]; then adopt=1; else pkgs+=("$a"); fi
  done
  [ ${#pkgs[@]} -eq 0 ] && pkgs=("${PACKAGES[@]}")

  cmd stow || {
    echo "stow not installed"
    exit 1
  }
  mkdir -p "$HOME/.config" "$HOME/.local/bin"
  unfold_config "$HOME/.config/herdr"
  unfold_config "$HOME/.config/kitty"
  unfold_config "$HOME/.config/nvim"
  if [ "$(os)" = mac ]; then
    unfold_config "$HOME/.config/aerospace"
    unfold_config "$HOME/.config/sketchybar"
    unfold_config "$HOME/.config/borders"
  fi

  if [ "$adopt" -eq 0 ]; then
    BACKUP="${BACKUP:-$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)}"
    backup_real "$HOME/.zshrc"
    backup_real "$HOME/.zshenv"
    backup_real "$HOME/.gitconfig"
    backup_real "$HOME/.config/nvim"
    backup_real "$HOME/.config/kitty/kitty.conf"
    backup_real "$HOME/.config/kitty/current-theme.conf"
    backup_real "$HOME/.config/oh-my-posh"
  fi

  local pkg stow_args=(-v -t "$HOME")
  [ "$adopt" -eq 1 ] && stow_args+=(--adopt)

  local all_pkgs=()
  while IFS= read -r pkg; do
    all_pkgs+=("$pkg")
  done < <(stow_package_list "${pkgs[@]}")

  for pkg in "${all_pkgs[@]}"; do
    (cd "$DOTFILES" && stow "${stow_args[@]}" "$pkg")
  done
}

usage() {
  cat <<EOF
usage: $0 [install|stow|adopt|unstow|dry-run|nvim|agent] [--cli cursor|kiro|both|none]
  install   packages + CLIs + stow (default)
  stow      symlink packages into \$HOME
  adopt     stow --adopt (moves conflicts into this repo — commit first)
  unstow    remove symlinks
  nvim      install latest Neovim from GitHub (Linux) or brew (Mac)
  agent     Gentle-AI + caveman + ponytail for Cursor/Kiro
  --cli     skip the prompt (mac/linux default: both; windows: cursor)
EOF
}

main() {
  local action=install cli="" kind
  kind="$(os)"
  while [ $# -gt 0 ]; do
    case "$1" in
    --cli)
      cli="${2:-}"
      shift 2
      ;;
    -h | --help | help)
      usage
      exit 0
      ;;
    install | stow | adopt | unstow | dry-run | nvim | agent)
      action="$1"
      shift
      ;;
    *)
      usage
      exit 1
      ;;
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
    *)
      echo "unsupported OS: $(uname -s)"
      exit 1
      ;;
    esac
    install_nvim
    install_nvm
    install_node
    install_lazygit
    install_treesitter_cli
    install_herdr
    install_mac_wm
    [ "$CLI_CURSOR" = 1 ] && install_cursor
    [ "$CLI_KIRO" = 1 ] && install_kiro
    setup_agents
    stow_packages "${PACKAGES[@]}"
    link_herdr_default_tabs
    start_mac_wm
    echo "done. open a new terminal or: exec zsh"
    echo "if this is still bash: chsh -s \"$(command -v zsh)\""
    ;;
  nvim)
    install_nvim
    command -v nvim && nvim --version | head -1
    ;;
  agent)
    need_git
    setup_agents
    ;;
  stow)
    stow_packages "${PACKAGES[@]}"
    link_herdr_default_tabs
    ;;
  adopt) stow_packages --adopt "${PACKAGES[@]}" ;;
  unstow)
    local pkg
    while IFS= read -r pkg; do
      (cd "$DOTFILES" && stow -D -t "$HOME" "$pkg")
    done < <(stow_package_list "${PACKAGES[@]}")
    ;;
  dry-run)
    local pkg
    while IFS= read -r pkg; do
      (cd "$DOTFILES" && stow -n -v -t "$HOME" "$pkg")
    done < <(stow_package_list "${PACKAGES[@]}")
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
