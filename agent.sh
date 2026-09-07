# Sourced by install.sh. Gentle-AI + caveman + ponytail for Cursor/Kiro.
# No Engram git sync / cloud — memory stays on this machine.

GENTLE_AI_INSTALL="https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh"
CAVEMAN_CACHE="${CAVEMAN_CACHE:-$HOME/.cache/dotfiles/caveman}"
CAVEMAN_REPO="https://github.com/JuliusBrussee/caveman.git"
PONYTAIL_CACHE="${PONYTAIL_CACHE:-$HOME/.cache/dotfiles/ponytail}"
PONYTAIL_REPO="https://github.com/DietrichGebert/ponytail.git"

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

gentle_ai_agents() {
  local agents=()
  has_cursor && agents+=("cursor")
  has_kiro && agents+=("kiro-ide")
  (IFS=,; echo "${agents[*]}")
}

install_gentle_ai() {
  export PATH="$HOME/.local/bin:$PATH"
  if cmd gentle-ai; then
    gentle-ai version
    return 0
  fi
  if [ "$(uname -s)" = Darwin ] && cmd brew; then
    brew install gentleman-programming/tap/gentle-ai 2>/dev/null ||
      brew upgrade gentle-ai 2>/dev/null || true
  else
    curl -fsSL "$GENTLE_AI_INSTALL" | bash
  fi
  cmd gentle-ai || {
    echo "gentle-ai not on PATH after install"
    return 1
  }
  gentle-ai version
}

setup_gentle_ai() {
  local agents
  agents="$(gentle_ai_agents)"
  [ -n "$agents" ] || {
    echo "no Cursor or Kiro found; skip gentle-ai"
    return 0
  }
  cmd gentle-ai || {
    echo "gentle-ai not on PATH"
    return 1
  }
  gentle-ai install \
    --agent "$agents" \
    --components engram,skills \
    --persona neutral
  if has_cursor; then
    rm -rf "$HOME/.cursor/skills/angular"
  fi
  if has_kiro; then
    rm -rf "$HOME/.kiro/skills/angular"
  fi
  echo "gentle-ai configured for: $agents"
}

sync_skill_repo() {
  local cache="$1" repo="$2"
  mkdir -p "$(dirname "$cache")"
  if [ -d "$cache/.git" ]; then
    git -C "$cache" pull --ff-only
  else
    rm -rf "$cache"
    git clone --depth 1 "$repo" "$cache"
  fi
}

link_skills_dir() {
  local src_root="$1" dest_root="$2"
  local skill_dir name dest
  mkdir -p "$dest_root"
  for skill_dir in "$src_root"/*/; do
    [ -f "${skill_dir}SKILL.md" ] || continue
    name="$(basename "$skill_dir")"
    dest="$dest_root/$name"
    rm -rf "$dest"
    ln -sfn "$skill_dir" "$dest"
  done
}

install_caveman_skills() {
  local dest did=0
  sync_skill_repo "$CAVEMAN_CACHE" "$CAVEMAN_REPO"
  if has_cursor; then
    dest="$HOME/.cursor/skills"
    link_skills_dir "$CAVEMAN_CACHE/skills" "$dest"
    [ -f "$CAVEMAN_CACHE/src/rules/caveman-activate.md" ] &&
      cp -f "$CAVEMAN_CACHE/src/rules/caveman-activate.md" "$HOME/.cursor/caveman-rule.md"
    did=1
    echo "caveman skills -> $dest"
  fi
  if has_kiro; then
    dest="$HOME/.kiro/skills"
    link_skills_dir "$CAVEMAN_CACHE/skills" "$dest"
    did=1
    echo "caveman skills -> $dest"
  fi
  [ "$did" = 1 ] || echo "no Cursor or Kiro found; skip caveman"
}

install_ponytail_skills() {
  local dest did=0
  sync_skill_repo "$PONYTAIL_CACHE" "$PONYTAIL_REPO"
  if has_cursor; then
    dest="$HOME/.cursor/skills"
    link_skills_dir "$PONYTAIL_CACHE/skills" "$dest"
    [ -f "$PONYTAIL_CACHE/.cursor/rules/ponytail.mdc" ] &&
      cp -f "$PONYTAIL_CACHE/.cursor/rules/ponytail.mdc" "$HOME/.cursor/ponytail-rule.mdc"
    did=1
    echo "ponytail skills -> $dest"
  fi
  if has_kiro; then
    dest="$HOME/.kiro/skills"
    link_skills_dir "$PONYTAIL_CACHE/skills" "$dest"
    [ -f "$PONYTAIL_CACHE/AGENTS.md" ] &&
      cp -f "$PONYTAIL_CACHE/AGENTS.md" "$HOME/.kiro/steering/ponytail.md"
    did=1
    echo "ponytail skills -> $dest"
  fi
  [ "$did" = 1 ] || echo "no Cursor or Kiro found; skip ponytail"
}

install_agent_skills() {
  install_caveman_skills
  install_ponytail_skills
}

check_agent_setup() {
  local fail=0
  export PATH="$HOME/.local/bin:$PATH"
  if ! has_cursor && ! has_kiro; then
    echo "check skipped: no Cursor or Kiro"
    return 0
  fi
  cmd gentle-ai || {
    echo "FAIL: gentle-ai missing"
    return 1
  }
  gentle-ai doctor || echo "warn: gentle-ai doctor reported issues"
  if has_cursor; then
    [ -f "$HOME/.cursor/skills/caveman/SKILL.md" ] || {
      echo "FAIL: caveman skill missing"
      fail=1
    }
    [ -f "$HOME/.cursor/skills/ponytail/SKILL.md" ] || {
      echo "FAIL: ponytail skill missing"
      fail=1
    }
    [ -f "$HOME/.cursor/caveman-rule.md" ] || echo "warn: no ~/.cursor/caveman-rule.md"
    [ -f "$HOME/.cursor/ponytail-rule.mdc" ] || echo "warn: no ~/.cursor/ponytail-rule.mdc"
    [ -e "$HOME/.cursor/skills/angular" ] && {
      echo "FAIL: angular skill still in Cursor"
      fail=1
    }
  fi
  if has_kiro; then
    [ -f "$HOME/.kiro/skills/caveman/SKILL.md" ] || {
      echo "FAIL: caveman skill missing (kiro)"
      fail=1
    }
    [ -f "$HOME/.kiro/skills/ponytail/SKILL.md" ] || {
      echo "FAIL: ponytail skill missing (kiro)"
      fail=1
    }
    [ -e "$HOME/.kiro/skills/angular" ] && {
      echo "FAIL: angular skill still in Kiro"
      fail=1
    }
  fi
  [ "$fail" = 0 ] || return 1
  echo "agent setup check ok"
}

setup_agents() {
  if ! has_cursor && ! has_kiro; then
    echo "Cursor/Kiro not present; skip gentle-ai setup"
    return 0
  fi
  need_git
  install_gentle_ai
  setup_gentle_ai
  install_agent_skills
  check_agent_setup
}
