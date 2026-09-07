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

function HasCursor {
  $wantCursor -or (Test-Path "$HOME\.cursor") -or (Has cursor) -or (Has agent)
}
function HasKiro {
  $wantKiro -or (Test-Path "$HOME\.kiro") -or (Has kiro-cli) -or (Has kiro)
}

function Install-Engram {
  $rel = Invoke-RestMethod "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest"
  $ver = $rel.tag_name.TrimStart("v")
  $arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
  } else { throw "unsupported arch" }
  $asset = $rel.assets | Where-Object { $_.name -eq "engram_${ver}_windows_${arch}.zip" } | Select-Object -First 1
  if (-not $asset) { throw "no engram zip for windows_$arch" }
  $binDir = Join-Path $HOME "bin"
  New-Item -ItemType Directory -Force -Path $binDir | Out-Null
  $zip = Join-Path $env:TEMP "engram.zip"
  Invoke-WebRequest $asset.browser_download_url -OutFile $zip
  Expand-Archive -Force $zip -DestinationPath (Join-Path $env:TEMP "engram-extract")
  $exe = Get-ChildItem (Join-Path $env:TEMP "engram-extract") -Recurse -Filter engram.exe | Select-Object -First 1
  Copy-Item $exe.FullName (Join-Path $binDir "engram.exe") -Force
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*$binDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$binDir;$userPath", "User")
  }
  $env:Path = "$binDir;" + $env:Path
  Write-Host "engram $ver -> $binDir\engram.exe"
}

function Set-EngramMcp($file) {
  $bin = (Get-Command engram).Source
  $data = @{ mcpServers = @{} }
  if (Test-Path $file) {
    $data = Get-Content $file -Raw | ConvertFrom-Json
  }
  if (-not $data.mcpServers) { $data | Add-Member mcpServers (@{}) -Force }
  $data.mcpServers | Add-Member -NotePropertyName engram -NotePropertyValue @{ command = $bin; args = @("mcp", "--tools=agent") } -Force
  $dir = Split-Path $file
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $data | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 $file
}

function Install-GentlemanSkills {
  $cache = Join-Path $HOME ".cache\dotfiles\gentleman-skills"
  New-Item -ItemType Directory -Force -Path (Split-Path $cache) | Out-Null
  if (Test-Path (Join-Path $cache ".git")) {
    git -C $cache pull --ff-only
  } else {
    git clone --depth 1 "https://github.com/Gentleman-Programming/Gentleman-Skills.git" $cache
  }
  $rels = @(
    "curated\react-19", "curated\nextjs-15", "curated\typescript", "curated\tailwind-4",
    "curated\zod-4", "curated\zustand-5", "curated\playwright", "curated\pytest",
    "curated\jira-task", "curated\jira-epic", "community\react-native"
  )
  $dests = @()
  if (HasCursor) { $dests += (Join-Path $HOME ".cursor\skills") }
  if (HasKiro) { $dests += (Join-Path $HOME ".kiro\skills") }
  foreach ($dest in $dests) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Remove-Item -Recurse -Force (Join-Path $dest "angular") -ErrorAction SilentlyContinue
    foreach ($rel in $rels) {
      $src = Join-Path $cache $rel
      $name = Split-Path $rel -Leaf
      $link = Join-Path $dest $name
      if (-not (Test-Path (Join-Path $src "SKILL.md"))) { throw "missing skill $rel" }
      if (Test-Path $link) { Remove-Item -Recurse -Force $link }
      New-Item -ItemType Junction -Path $link -Target $src | Out-Null
    }
    Write-Host "Gentleman skills -> $dest"
  }
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
  Install-GentlemanSkills
  Install-CavemanSkills
  Install-PonytailSkills
}

if ((HasCursor) -or (HasKiro)) {
  Install-Engram
  if (HasCursor) {
    engram setup cursor
    Set-EngramMcp (Join-Path $HOME ".cursor\mcp.json")
  }
  if (HasKiro) {
    engram setup kiro
    Set-EngramMcp (Join-Path $HOME ".kiro\settings\mcp.json")
  }
  Install-AgentSkills
}

Write-Host @"
Native Windows has nvim + git + fzf + lazygit + zoxide + nvm + herdr$(if ($wantCursor) { ' + Cursor CLI' } else { '' }).
For zsh, zinit, kitty, GNU Stow$(if ($wantKiro) { ', and Kiro CLI' } else { '' }):
  wsl --install
  then inside WSL: git clone <this-repo> ~/dotfiles && ~/dotfiles/install.sh
"@
