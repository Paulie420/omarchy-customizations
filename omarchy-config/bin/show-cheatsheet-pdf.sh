#!/bin/bash
# Generate and open the Hyprland keybind cheat sheet as a PDF.
# Requires: hypr-cheatgen.py, python-reportlab, zathura or evince

set -euo pipefail

export PATH="$HOME/.config/omarchy/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

CHEAT_DIR="$HOME/.config/omarchy/cheats"
TXT="$CHEAT_DIR/hypr-binds.txt"
PDF="$CHEAT_DIR/hypr-binds.pdf"
CHEATGEN="$HOME/.config/omarchy/bin/hypr-cheatgen.py"

mkdir -p "$CHEAT_DIR"

# Regenerate (always current)
"$CHEATGEN" --format ascii --width 80 --out "$TXT" \
  --pdf "$PDF" --pdf-font-size 15 --pdf-line-height 17

# Open PDF viewer
if command -v zathura >/dev/null 2>&1; then
  exec zathura "$PDF"
elif command -v evince >/dev/null 2>&1; then
  exec evince "$PDF"
else
  exec xdg-open "$PDF"
fi
