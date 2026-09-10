
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

export PATH="$HOME/.local/bin:$PATH"

# Windows Terminal / WSL has no Kitty wrapper. Skip if already inside herdr.
if [[ -o interactive && -t 1 && -z "${HERDR_ENV:-}" && -z "${HERDR_SKIP:-}" && -z "${TMUX:-}" ]] \
  && command -v herdr >/dev/null 2>&1; then
  exec herdr
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit ice as"program" from"gh-r" mv"posh-* -> oh-my-posh" bcat"sys" atclone"./oh-my-posh completion zsh > _oh-my-posh" atpull"%atclone"
zinit load JanDeDobbeleer/oh-my-posh

OMP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/oh-my-posh/catppuccin_frappe.omp.json"
eval "$(oh-my-posh init zsh --config "$OMP_CONFIG")"

zinit light zdharma-continuum/zinit-package-fzf

zinit ice wait"0" lucid as"command" from"gh-r" mv"zoxide*/zoxide -> zoxide" atclone"./zoxide init zsh > init.zsh" atpull"%atclone" src"init.zsh"
zinit light ajeetdsouza/zoxide

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZL::git.zsh
zinit snippet OMZP::git

autoload -Uz compinit && compinit
zinit cdreplay -q

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

alias ls='ls --color'
alias vim='nvim'
alias c='clear'
alias lg='lazygit'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && [ ! -s "$NVM_DIR/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

if command -v fzf >/dev/null 2>&1; then
  # apt fzf on Ubuntu is often < 0.48 and has no --zsh
  case "$(fzf --version 2>/dev/null)" in
    0.[0-3]*|0.4[0-7]*)
      for _fzf in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh \
                  /usr/share/doc/fzf/examples/completion.zsh /usr/share/fzf/completion.zsh; do
        [ -r "$_fzf" ] && . "$_fzf"
      done
      unset _fzf
      ;;
    *) eval "$(fzf --zsh)" ;;
  esac
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"

# Vim for command editing (Esc). Insert keeps emacs autocomplete chords.
bindkey -v
bindkey -M viins '^P' history-search-backward
bindkey -M viins '^N' history-search-forward
bindkey -M viins '^F' vi-forward-char

if command -v herdr >/dev/null 2>&1; then
  eval "$(herdr completion zsh)"
fi

export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && . "$HOME/.bun/_bun"


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
