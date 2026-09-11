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
| `aerospace` | `~/.config/aerospace` (macOS only) |
| `sketchybar` | `~/.config/sketchybar` (macOS only) |
| `borders` | `~/.config/borders` (macOS only) |

## Install

**macOS / Linux / WSL**

```sh
git clone https://github.com/rox651/dotfiles_v2.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
nvim
```

The script installs git, stow, zsh, latest Neovim, Node LTS (npm, yarn, pnpm via nvm), fzf/zoxide (via zinit), lazygit, kitty (mac), fd, ripgrep, herdr, AeroSpace + SketchyBar (mac), then symlinks this repo into `$HOME`. Existing `~/.zshrc` / nvim files are moved to `~/.dotfiles-backup-*`.

On macOS, grant **Accessibility** to AeroSpace and SketchyBar in System Settings → Privacy & Security.

**Wallpaper gradient** (keeps your image, adds a dark Catppuccin fade on top):

```sh
wallpaper-overlay              # apply (default opacity 0.42)
wallpaper-overlay --opacity 0.55
wallpaper-overlay --refresh    # after you change the wallpaper in System Settings
wallpaper-overlay --reset      # restore original
```

It asks which agent CLIs to install (Cursor, Kiro, Claude Code, combinations, neither). Default: **Cursor + Kiro** on Mac/Linux, **Cursor** on Windows.

```sh
./install.sh --cli cursor
./install.sh --cli all
./install.sh --cli cursor,claude
```

Then: `agent login`, `kiro-cli`, and/or `claude` to authenticate.

Install also runs **[Gentle-AI](https://github.com/Gentleman-Programming/gentle-ai)** (Engram memory, skills, SDD) plus **caveman** and **ponytail** on whichever of Cursor / Kiro / Claude Code exists. Memory is **not** synced between machines. Re-run just that:

```sh
./install.sh agent
```

Gentle-AI manages Engram + skills (Angular excluded). Caveman and ponytail stay separate. Cursor: `~/.cursor/skills/`. Kiro: `~/.kiro/skills/`. Claude Code: `~/.claude/skills/`.

Cursor ignores global `.mdc` rules. After `./install.sh agent`, paste into **Settings → Rules → User Rules** once:

- `~/.cursor/engram-memory-protocol.md`
- `~/.cursor/ponytail-rule.mdc` (always-on lazy-dev mode)
- `~/.cursor/caveman-rule.md` (optional always-on terse mode; or invoke `/caveman` per session)

Kiro already loads `~/.kiro/steering/engram.md` and `~/.kiro/steering/ponytail.md`. Claude Code picks up skills from `~/.claude/skills/` (Gentle-AI also writes `~/.claude/CLAUDE.md`).

**Windows (native)** — nvim/git/CLIs only:

```powershell
git clone https://github.com/rox651/dotfiles_v2.git $HOME\dotfiles
cd $HOME\dotfiles
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

For zsh, Stow, kitty, and Kiro: install WSL, clone inside it, run `./install.sh`.

Do not commit secrets (SSH keys, `~/.cursor/cli-config.json`, MCP tokens).
