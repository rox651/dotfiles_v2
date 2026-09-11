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

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Has nvm) {
  nvm install lts
  nvm use lts
}
npm install -g yarn pnpm tree-sitter-cli

Write-Host ""
Write-Host "Which agent CLIs?"
Write-Host "  1) Cursor"
Write-Host "  2) Kiro (needs WSL on Windows)"
Write-Host "  3) Both (Cursor + Kiro)"
Write-Host "  4) Neither"
Write-Host "  5) Claude Code"
Write-Host "  6) All"
$choice = Read-Host "Choice [1]"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

$wantCursor = $choice -in @("1", "3", "6", "cursor", "both", "all")
$wantKiro = $choice -in @("2", "3", "6", "kiro", "both", "all")
$wantClaude = $choice -in @("5", "6", "claude", "claude-code", "all")

if ($wantCursor) {
  irm 'https://cursor.com/install?win32=true' | iex
}

if ($wantKiro) {
  Write-Host "Kiro CLI is not a native Windows install. In WSL: ~/dotfiles/install.sh --cli kiro"
}

if ($wantClaude) {
  irm https://claude.ai/install.ps1 | iex
}

if (-not (Has herdr)) {
  irm https://herdr.dev/install.ps1 | iex
}

function HasCursor {
  $wantCursor -or (Test-Path "$HOME\.cursor") -or (Has cursor) -or (Has agent)
}
function HasKiro {
  $wantKiro -or (Test-Path "$HOME\.kiro") -or (Has kiro-cli) -or (Has kiro)
}
function HasClaude {
  $wantClaude -or (Test-Path "$HOME\.claude") -or (Has claude)
}

function Install-GentleAi {
  if (Has gentle-ai) {
    gentle-ai version
    return
  }
  if (-not (Has go)) {
    if (Has winget) {
      winget install -e --id GoLang.Go --accept-source-agreements --accept-package-agreements
    } else {
      throw "Go required for gentle-ai on Windows: winget install GoLang.Go"
    }
  }
  go install github.com/gentleman-programming/gentle-ai/v2/cmd/gentle-ai@latest
  $goBin = Join-Path (go env GOPATH) "bin"
  if ($env:Path -notlike "*$goBin*") {
    $env:Path = "$goBin;" + $env:Path
  }
  gentle-ai version
}

function Setup-GentleAi {
  $agents = @()
  if (HasCursor) { $agents += "cursor" }
  if (HasKiro) { $agents += "kiro-ide" }
  if (HasClaude) { $agents += "claude-code" }
  if ($agents.Count -eq 0) {
    Write-Host "no Cursor, Kiro, or Claude Code found; skip gentle-ai"
    return
  }
  gentle-ai install --agent ($agents -join ",") --components engram,skills --persona neutral
  foreach ($dest in @(
    $(if (HasCursor) { Join-Path $HOME ".cursor\skills" }),
    $(if (HasKiro) { Join-Path $HOME ".kiro\skills" }),
    $(if (HasClaude) { Join-Path $HOME ".claude\skills" })
  )) {
    if ($dest) {
      Remove-Item -Recurse -Force (Join-Path $dest "angular") -ErrorAction SilentlyContinue
    }
  }
  Write-Host "gentle-ai configured for: $($agents -join ',')"
}

function Sync-SkillRepo {
  param([string]$Cache, [string]$Repo)
  New-Item -ItemType Directory -Force -Path (Split-Path $Cache) | Out-Null
  if (Test-Path (Join-Path $Cache ".git")) {
    git -C $Cache pull --ff-only
  } else {
    if (Test-Path $Cache) { Remove-Item -Recurse -Force $Cache }
    git clone --depth 1 $Repo $Cache
  }
}

function Link-SkillsDir {
  param([string]$SrcRoot, [string]$DestRoot)
  New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null
  foreach ($skillDir in Get-ChildItem -Path $SrcRoot -Directory) {
    if (-not (Test-Path (Join-Path $skillDir.FullName "SKILL.md"))) { continue }
    $link = Join-Path $DestRoot $skillDir.Name
    if (Test-Path $link) { Remove-Item -Recurse -Force $link }
    New-Item -ItemType Junction -Path $link -Target $skillDir.FullName | Out-Null
  }
}

function Install-CavemanSkills {
  $cache = Join-Path $HOME ".cache\dotfiles\caveman"
  Sync-SkillRepo $cache "https://github.com/JuliusBrussee/caveman.git"
  $dests = @()
  if (HasCursor) { $dests += (Join-Path $HOME ".cursor\skills") }
  if (HasKiro) { $dests += (Join-Path $HOME ".kiro\skills") }
  if (HasClaude) { $dests += (Join-Path $HOME ".claude\skills") }
  foreach ($dest in $dests) {
    Link-SkillsDir (Join-Path $cache "skills") $dest
    Write-Host "caveman skills -> $dest"
  }
  $rule = Join-Path $cache "src\rules\caveman-activate.md"
  if ((HasCursor) -and (Test-Path $rule)) {
    Copy-Item -Force $rule (Join-Path $HOME ".cursor\caveman-rule.md")
  }
}

function Install-PonytailSkills {
  $cache = Join-Path $HOME ".cache\dotfiles\ponytail"
  Sync-SkillRepo $cache "https://github.com/DietrichGebert/ponytail.git"
  $dests = @()
  if (HasCursor) { $dests += (Join-Path $HOME ".cursor\skills") }
  if (HasKiro) { $dests += (Join-Path $HOME ".kiro\skills") }
  if (HasClaude) { $dests += (Join-Path $HOME ".claude\skills") }
  foreach ($dest in $dests) {
    Link-SkillsDir (Join-Path $cache "skills") $dest
    Write-Host "ponytail skills -> $dest"
  }
  $cursorRule = Join-Path $cache ".cursor\rules\ponytail.mdc"
  if ((HasCursor) -and (Test-Path $cursorRule)) {
    Copy-Item -Force $cursorRule (Join-Path $HOME ".cursor\ponytail-rule.mdc")
  }
  $kiroRule = Join-Path $cache "AGENTS.md"
  if ((HasKiro) -and (Test-Path $kiroRule)) {
    $steering = Join-Path $HOME ".kiro\steering"
    New-Item -ItemType Directory -Force -Path $steering | Out-Null
    Copy-Item -Force $kiroRule (Join-Path $steering "ponytail.md")
  }
}

function Install-AgentSkills {
  Install-CavemanSkills
  Install-PonytailSkills
}

if ((HasCursor) -or (HasKiro) -or (HasClaude)) {
  Install-GentleAi
  Setup-GentleAi
  Install-AgentSkills
  gentle-ai doctor
}

Write-Host @"
Native Windows has nvim + git + fzf + lazygit + zoxide + nvm + herdr$(if ($wantCursor) { ' + Cursor CLI' } else { '' })$(if ($wantClaude) { ' + Claude Code' } else { '' }).
For zsh, zinit, kitty, GNU Stow$(if ($wantKiro) { ', and Kiro CLI' } else { '' }):
  wsl --install
  then inside WSL: git clone <this-repo> ~/dotfiles && ~/dotfiles/install.sh
"@
