# Native Windows helper. Full zsh/stow/kitty stack lives in WSL — run install.sh there.
# Requires: winget (Windows 11) or scoop.

$ErrorActionPreference = "Stop"

function Has($name) { Get-Command $name -ErrorAction SilentlyContinue }

if (Has winget) {
  winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
  winget install -e --id Neovim.Neovim --accept-source-agreements --accept-package-agreements
  winget install -e --id junegunn.fzf --accept-source-agreements --accept-package-agreements
  winget install -e --id JesseDuffield.lazygit --accept-source-agreements --accept-package-agreements
  winget install -e --id ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements
  winget install -e --id CoreyButler.NVMforWindows --accept-source-agreements --accept-package-agreements
} elseif (Has scoop) {
  scoop install git neovim fzf lazygit zoxide nvm
} else {
  Write-Host "Install winget or scoop, then re-run."
  exit 1
}

Write-Host ""
Write-Host "Which agent CLIs?"
Write-Host "  1) Cursor"
Write-Host "  2) Kiro (needs WSL on Windows)"
Write-Host "  3) Both"
Write-Host "  4) Neither"
$choice = Read-Host "Choice [1]"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

$wantCursor = $choice -in @("1", "3", "cursor", "both")
$wantKiro = $choice -in @("2", "3", "kiro", "both")

if ($wantCursor) {
  irm 'https://cursor.com/install?win32=true' | iex
}

if ($wantKiro) {
  Write-Host "Kiro CLI is not a native Windows install. In WSL: ~/dotfiles/install.sh --cli kiro"
}

if (-not (Has herdr)) {
  irm https://herdr.dev/install.ps1 | iex
}

Write-Host @"
Native Windows has nvim + git + fzf + lazygit + zoxide + nvm + herdr$(if ($wantCursor) { ' + Cursor CLI' } else { '' }).
For zsh, zinit, kitty, GNU Stow$(if ($wantKiro) { ', and Kiro CLI' } else { '' }):
  wsl --install
  then inside WSL: git clone <this-repo> ~/dotfiles && ~/dotfiles/install.sh
"@
