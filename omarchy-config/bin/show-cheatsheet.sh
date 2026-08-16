#!/bin/bash
set -euo pipefail

# Ensure Hypr can find your stuff even if it doesn't inherit your shell PATH
export PATH="$HOME/.config/omarchy/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

CHEAT_DIR="$HOME/.config/omarchy/cheats"
TXT="$CHEAT_DIR/hypr-binds.txt"
MD="$CHEAT_DIR/hypr-binds.md"
PDF="$CHEAT_DIR/hypr-binds.pdf"

CHEATGEN="$HOME/.config/omarchy/bin/hypr-cheatgen.py"
# Launch through the user's default terminal (foot/ghostty/kitty/alacritty)
# instead of hardcoding one. The app-id gives Hyprland a stable handle for
# the float+center window rule in ~/.config/hypr/looknfeel.lua.
APP_ID="org.omarchy.custom-tui"

mkdir -p "$CHEAT_DIR"

# sanity checks with visible feedback
if [[ ! -x "$CHEATGEN" ]]; then
  notify-send "Cheat sheet" "hypr-cheatgen.py not executable: $CHEATGEN"
  exit 1
fi

if ! command -v omarchy-launch-tui >/dev/null 2>&1; then
  notify-send "Cheat sheet" "omarchy-launch-tui not found on PATH"
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

# Open in terminal with less (no wrap, keep alignment)
#exec "$TERM_BIN" --title "Hypr Cheat Sheet" -e bash -lc "less -SR '$TXT'"
exec omarchy-launch-tui --app-id="$APP_ID" bash -lc "printf \"\033]0;Omarchy · Keybind Cheatsheet\007\"; less -SR '$TXT'"

