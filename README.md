# Dotfiles (GNU Stow)

Personal config farm. Clone, run the installer, get the same shell + nvim on another machine.

**Needs:** git, [GNU Stow](https://www.gnu.org/software/stow/). The installer installs the rest.

## Layout

Each folder is a Stow package. Paths inside a package match `$HOME`.

| Package | Links to |
|---------|----------|
| `zsh` | `~/.zshrc`, `~/.zshenv` |
| `git` | `~/.gitconfig` |
| `nvim` | `~/.config/nvim` |
| `kitty` | `~/.config/kitty` |
| `omp` | `~/.config/oh-my-posh` |
| `herdr` | `~/.config/herdr` (Kitty attach helper) |

## Install

**macOS / Linux / WSL**

```sh
git clone <your-remote> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Installs: stow, zsh, nvim, fzf, zoxide, lazygit, nvm, kitty (mac), fd, ripgrep, **herdr**, then stows into `$HOME`.

Asks which agent CLIs to install (Cursor, Kiro, both, neither). Default: **both** on Mac/Linux, **Cursor** on Windows.

```sh
./install.sh --cli cursor   # skip prompt
./install.sh --cli both
```

Existing `~/.zshrc` / `~/.config/nvim` (Ubuntu defaults) are moved to `~/.dotfiles-backup-*`, then replaced with symlinks. Re-run after `git pull`:

```sh
./install.sh stow
```

**Windows (native)** — editor/CLI tools only:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./install.ps1
```

Then install WSL and run `./install.sh` inside it for zsh/stow/kitty/Kiro.

## After clone, without the installer

```sh
cd ~/dotfiles
stow -t ~ zsh git kitty nvim omp herdr
```

Conflicts: `./install.sh stow` backs them up first. `./install.sh adopt` imports the live files into this repo instead.

## New machine checklist

1. Clone this repo
2. `./install.sh`
3. `exec zsh`
4. `nvim` (LazyVim will fetch plugins)
5. `agent login` / `kiro-cli` to auth CLIs

Do not commit secrets (SSH keys, `~/.cursor/cli-config.json`, MCP tokens).
