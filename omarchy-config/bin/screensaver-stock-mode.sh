#!/usr/bin/env bash
# Thin wrapper kept so the Omarchy menu and any keybinds keep working.
# Real logic (and the Quattro shell.json migration note) lives in
# screensaver-set-mode.sh
exec "$HOME/.config/omarchy/bin/screensaver-set-mode.sh" stock "$@"
