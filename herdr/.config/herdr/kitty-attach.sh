#!/bin/sh
# Kitty entry: attach herdr. Plugin seeds agent/code/server on each new space.
export PATH="$HOME/.local/bin:$PATH"

if [ -n "$HERDR_ENV" ]; then
  exec "${SHELL:-/bin/zsh}" "$@"
fi

# `herdr server` is headless and stays in the foreground. Running it here
# made Kitty's first tab look empty; Cmd+N then attached for real.
if ! herdr status server >/dev/null 2>&1; then
  herdr server >/dev/null 2>&1 &
  # ponytail: fixed 0.2s; raise if `tab list` races before the socket is up
  sleep 0.2
fi

SEED="$HOME/.config/herdr/default-tabs/ensure-tabs.py"
if [ -f "$SEED" ]; then
  python3 "$SEED" || true
fi

exec herdr
