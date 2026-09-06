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

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

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

export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && [ ! -s "$NVM_DIR/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"

if command -v herdr >/dev/null 2>&1; then
  eval "$(herdr completion zsh)"
fi

export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && . "$HOME/.bun/_bun"
