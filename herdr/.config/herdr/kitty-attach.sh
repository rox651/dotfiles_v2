#!/bin/sh
# Kitty entry: attach herdr. On first empty session, seed agent + code tabs.
export PATH="$HOME/.local/bin:$PATH"

if [ -n "$HERDR_ENV" ]; then
  exec "${SHELL:-/bin/zsh}" "$@"
fi

herdr server >/dev/null 2>&1 || true

python3 - <<'PY'
import json, subprocess

def run(*args):
    subprocess.run(["herdr", *args], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

raw = subprocess.check_output(["herdr", "tab", "list"], text=True)
tabs = json.loads(raw)["result"]["tabs"]
if len(tabs) != 1:
    raise SystemExit(0)
t = tabs[0]
if t.get("label") != "1":
    raise SystemExit(0)
run("tab", "rename", t["tab_id"], "agent")
run("tab", "create", "--workspace", t["workspace_id"], "--label", "code", "--no-focus")
PY

exec herdr
