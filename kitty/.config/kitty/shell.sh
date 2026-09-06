#!/bin/sh
# Use herdr when installed; otherwise a normal zsh login shell.
export PATH="$HOME/.local/bin:$PATH"
if command -v herdr >/dev/null 2>&1 && [ -x "$HOME/.config/herdr/kitty-attach.sh" ]; then
  exec "$HOME/.config/herdr/kitty-attach.sh" "$@"
fi
exec "${SHELL:-/bin/zsh}" "$@"
