# Dotfiles (GNU Stow)

Clone, run the installer, get the same shell + nvim on another machine.

## Layout

Each folder is a Stow package. Paths inside a package match `$HOME`.

| Package | Links to |
|---------|----------|
| `zsh` | `~/.zshrc`, `~/.zshenv` |
| `git` | `~/.gitconfig` |
| `nvim` | `~/.config/nvim` |
| `kitty` | `~/.config/kitty` |
| `omp` | `~/.config/oh-my-posh` |
| `herdr` | `~/.config/herdr` |

## Install

**macOS / Linux / WSL**

```sh
git clone https://github.com/rox651/dotfiles_v2.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
nvim
```

The script installs git, stow, zsh, latest Neovim, Node LTS (npm, yarn, pnpm via nvm), fzf/zoxide (via zinit), lazygit, kitty (mac), fd, ripgrep, herdr, then symlinks this repo into `$HOME`. Existing `~/.zshrc` / nvim files are moved to `~/.dotfiles-backup-*`.

It asks which agent CLIs to install (Cursor, Kiro, both, neither). Default: **both** on Mac/Linux, **Cursor** on Windows.

```sh
./install.sh --cli cursor
```

Then: `agent login` and/or `kiro-cli` to authenticate.

Install also runs **[Gentle-AI](https://github.com/Gentleman-Programming/gentle-ai)** (Engram memory, skills, SDD) plus **caveman** and **ponytail** on whichever of Cursor / Kiro exists. Memory is **not** synced between machines. Re-run just that:

```sh
./install.sh agent
```

Gentle-AI manages Engram + skills (Angular excluded). Caveman and ponytail stay separate. Cursor: `~/.cursor/skills/`. Kiro: `~/.kiro/skills/`.

Cursor ignores global `.mdc` rules. After `./install.sh agent`, paste into **Settings → Rules → User Rules** once:

- `~/.cursor/engram-memory-protocol.md`
- `~/.cursor/ponytail-rule.mdc` (always-on lazy-dev mode)
- `~/.cursor/caveman-rule.md` (optional always-on terse mode; or invoke `/caveman` per session)

Kiro already loads `~/.kiro/steering/engram.md` and `~/.kiro/steering/ponytail.md`.

**Windows (native)** — nvim/git/CLIs only:

```powershell
git clone https://github.com/rox651/dotfiles_v2.git $HOME\dotfiles
cd $HOME\dotfiles
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

For zsh, Stow, kitty, and Kiro: install WSL, clone inside it, run `./install.sh`.

Do not commit secrets (SSH keys, `~/.cursor/cli-config.json`, MCP tokens).
