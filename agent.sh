# Sourced by install.sh. Local Engram + selected Gentleman-Skills for Cursor/Kiro.
# No Engram git sync / cloud — memory stays on this machine.

SKILLS_CACHE="${SKILLS_CACHE:-$HOME/.cache/dotfiles/gentleman-skills}"
SKILLS_REPO="https://github.com/Gentleman-Programming/Gentleman-Skills.git"
ENGRAM_REPO="Gentleman-Programming/engram"

# Frontend minus angular. Testing. Workflow. Community: react-native only.
GENTLEMAN_SKILLS=(
  curated/react-19
  curated/nextjs-15
  curated/typescript
  curated/tailwind-4
  curated/zod-4
  curated/zustand-5
  curated/playwright
  curated/pytest
  curated/jira-task
  curated/jira-epic
  community/react-native
)

has_cursor() {
  [ "${CLI_CURSOR:-0}" = 1 ] && return 0
  [ -d "$HOME/.cursor" ] && return 0
  cmd agent || cmd cursor-agent || cmd cursor
}

has_kiro() {
  [ "${CLI_KIRO:-0}" = 1 ] && return 0
  [ -d "$HOME/.kiro" ] && return 0
  cmd kiro-cli || cmd kiro
}

engram_arch() {
  local osn arch
  osn="$(uname -s)"
  case "$(uname -m)" in
  x86_64 | amd64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *)
    echo "unknown arch for engram: $(uname -m)" >&2
    return 1
    ;;
  esac
  case "$osn" in
  Darwin) echo "darwin_${arch}" ;;
  Linux) echo "linux_${arch}" ;;
  *)
    echo "unknown OS for engram: $osn" >&2
    return 1
    ;;
  esac
}

install_engram() {
  export PATH="$HOME/.local/bin:$PATH"
  mkdir -p "$HOME/.local/bin"

  local ver plat asset tmp bin
  ver="$(curl -fsSL "https://api.github.com/repos/${ENGRAM_REPO}/releases/latest" | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || {
    echo "could not resolve latest engram version"
    return 1
  }
  plat="$(engram_arch)"
  asset="engram_${ver}_${plat}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/${ENGRAM_REPO}/releases/download/v${ver}/${asset}" -o "$tmp/engram.tgz"
  tar -C "$tmp" -xzf "$tmp/engram.tgz"
  bin="$(find "$tmp" -type f -name engram | head -1)"
  [ -n "$bin" ] || {
    echo "engram binary missing from $asset"
    rm -rf "$tmp"
    return 1
  }
  install -m 755 "$bin" "$HOME/.local/bin/engram"
  rm -rf "$tmp"
  echo "engram $ver -> $HOME/.local/bin/engram"
}

# Merge MCP JSON. Never replace other servers (Sanity, Better Auth, …).
mcp_set_engram() {
  local file="$1"
  local bin
  bin="$(command -v engram)"
  [ -n "$bin" ] || {
    echo "engram not on PATH"
    return 1
  }
  python3 - "$file" "$bin" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
bin_path = sys.argv[2]
data = {}
if p.exists() and p.stat().st_size:
    data = json.loads(p.read_text())
if not isinstance(data, dict):
    data = {}
servers = data.get("mcpServers")
if not isinstance(servers, dict):
    servers = {}
servers["engram"] = {"command": bin_path, "args": ["mcp", "--tools=agent"]}
data["mcpServers"] = servers
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, indent=2) + "\n")
PY
}

setup_engram_agents() {
  cmd engram || {
    echo "engram not on PATH"
    return 1
  }
  local did=0
  if has_cursor; then
    engram setup cursor || true
    mcp_set_engram "$HOME/.cursor/mcp.json"
    did=1
    echo "engram wired for Cursor"
  fi
  if has_kiro; then
    engram setup kiro || true
    mcp_set_engram "$HOME/.kiro/settings/mcp.json"
    did=1
    echo "engram wired for Kiro"
  fi
  if [ "$did" = 0 ]; then
    echo "no Cursor or Kiro found; skip engram agent setup"
  fi
}

sync_gentleman_skills_repo() {
  mkdir -p "$(dirname "$SKILLS_CACHE")"
  if [ -d "$SKILLS_CACHE/.git" ]; then
    git -C "$SKILLS_CACHE" pull --ff-only
  else
    rm -rf "$SKILLS_CACHE"
    git clone --depth 1 "$SKILLS_REPO" "$SKILLS_CACHE"
  fi
}

link_skill() {
  local rel="$1" dest_root="$2"
  local src="$SKILLS_CACHE/$rel"
  local name dest
  name="$(basename "$rel")"
  dest="$dest_root/$name"
  [ -f "$src/SKILL.md" ] || {
    echo "missing skill: $rel"
    return 1
  }
  mkdir -p "$dest_root"
  rm -rf "$dest"
  ln -sfn "$src" "$dest"
}

install_gentleman_skills() {
  local dest did=0
  sync_gentleman_skills_repo
  if has_cursor; then
    dest="$HOME/.cursor/skills"
    mkdir -p "$dest"
    rm -rf "$dest/angular"
    for rel in "${GENTLEMAN_SKILLS[@]}"; do
      link_skill "$rel" "$dest"
    done
    did=1
    echo "Gentleman skills -> $dest"
  fi
  if has_kiro; then
    dest="$HOME/.kiro/skills"
    mkdir -p "$dest"
    rm -rf "$dest/angular"
    for rel in "${GENTLEMAN_SKILLS[@]}"; do
      link_skill "$rel" "$dest"
    done
    did=1
    echo "Gentleman skills -> $dest"
  fi
  if [ "$did" = 0 ]; then
    echo "no Cursor or Kiro found; skip skills"
  fi
}

mcp_has_engram() {
  local file="$1"
  [ -f "$file" ] || return 1
  python3 - "$file" <<'PY'
import json, sys
p = sys.argv[1]
data = json.loads(open(p).read())
servers = data.get("mcpServers") or {}
sys.exit(0 if "engram" in servers else 1)
PY
}

check_agent_setup() {
  local fail=0 rel name dest
  export PATH="$HOME/.local/bin:$PATH"
  if ! has_cursor && ! has_kiro; then
    echo "check skipped: no Cursor or Kiro"
    return 0
  fi
  cmd engram || {
    echo "FAIL: engram missing"
    return 1
  }
  engram version
  if has_cursor; then
    mcp_has_engram "$HOME/.cursor/mcp.json" || {
      echo "FAIL: Cursor mcp.json missing engram"
      fail=1
    }
    [ -f "$HOME/.cursor/engram-memory-protocol.md" ] || echo "warn: no ~/.cursor/engram-memory-protocol.md"
  fi
  if has_kiro; then
    mcp_has_engram "$HOME/.kiro/settings/mcp.json" || {
      echo "FAIL: Kiro mcp.json missing engram"
      fail=1
    }
    [ -f "$HOME/.kiro/steering/engram.md" ] || echo "warn: no ~/.kiro/steering/engram.md (engram setup)"
  fi
  for rel in "${GENTLEMAN_SKILLS[@]}"; do
    name="$(basename "$rel")"
    if has_cursor; then
      dest="$HOME/.cursor/skills/$name/SKILL.md"
      [ -f "$dest" ] || {
        echo "FAIL: $dest"
        fail=1
      }
    fi
    if has_kiro; then
      dest="$HOME/.kiro/skills/$name/SKILL.md"
      [ -f "$dest" ] || {
        echo "FAIL: $dest"
        fail=1
      }
    fi
  done
  if has_cursor && [ -e "$HOME/.cursor/skills/angular" ]; then
    echo "FAIL: angular skill still in Cursor"
    fail=1
  fi
  if has_kiro && [ -e "$HOME/.kiro/skills/angular" ]; then
    echo "FAIL: angular skill still in Kiro"
    fail=1
  fi
  [ "$fail" = 0 ] || return 1
  echo "agent setup check ok"
}

setup_agents() {
  if ! has_cursor && ! has_kiro; then
    echo "Cursor/Kiro not present; skip Engram and Gentleman skills"
    return 0
  fi
  need_git
  install_engram
  setup_engram_agents
  install_gentleman_skills
  check_agent_setup
}
