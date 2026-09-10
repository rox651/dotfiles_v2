#!/usr/bin/env bash
# Bridge AeroSpace events to sketchybar.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOCKDIR="$HOME/.cache/sketchybar-aerospace-listener.lock"
mkdir -p "$(dirname "$LOCKDIR")"

if [ -d "$LOCKDIR" ]; then
  oldpid="$(cat "$LOCKDIR/pid" 2>/dev/null || true)"
  if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$LOCKDIR"
fi

mkdir "$LOCKDIR"
echo "$$" >"$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT

aerospace subscribe --all | while IFS= read -r _; do
  sketchybar --trigger aerospace_refresh 2>/dev/null || true
done
