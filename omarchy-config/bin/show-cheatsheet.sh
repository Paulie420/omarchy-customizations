#!/bin/bash
# Generate and display the Hyprland keybind cheat sheet in a terminal.
# Requires: hypr-cheatgen.py, alacritty, less
# Pass --all to also generate Markdown + PDF versions.

set -euo pipefail

# Ensure Hypr can find your stuff even if it doesn't inherit your shell PATH
export PATH="$HOME/.config/omarchy/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

CHEAT_DIR="$HOME/.config/omarchy/cheats"
TXT="$CHEAT_DIR/hypr-binds.txt"
MD="$CHEAT_DIR/hypr-binds.md"
PDF="$CHEAT_DIR/hypr-binds.pdf"

CHEATGEN="$HOME/.config/omarchy/bin/hypr-cheatgen.py"
TERM_BIN="/usr/bin/alacritty"

mkdir -p "$CHEAT_DIR"

if [[ ! -x "$CHEATGEN" ]]; then
  notify-send "Cheat sheet" "hypr-cheatgen.py not executable: $CHEATGEN"
  exit 1
fi

if [[ ! -x "$TERM_BIN" ]]; then
  notify-send "Cheat sheet" "Alacritty not found at $TERM_BIN"
  exit 1
fi

# Always regenerate TXT (fast)
"$CHEATGEN" --format ascii --width 80 --out "$TXT"

# Optional: regenerate MD + PDF when asked
if [[ "${1:-}" == "--all" ]]; then
  "$CHEATGEN" --format md --out "$MD"
  "$CHEATGEN" --format ascii --width 80 --out "$TXT" \
    --pdf "$PDF" --pdf-font-size 15 --pdf-line-height 17
fi

# Open in terminal with less (no wrap, keeps alignment)
exec "$TERM_BIN" --class CheatSheet -e bash -lc "less -SR '$TXT'"
