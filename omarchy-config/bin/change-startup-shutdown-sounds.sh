#!/usr/bin/env bash
# Interactive picker to select a Windows-era sound theme.
# Copies the selected theme's files to startup.mp3 and shutdown.mp3.
# The omarchy-launch-walker dmenu UI is used for selection.
#
# Sound files must be placed in ~/.config/omarchy/sounds/:
#   win2000startup.mp3 / win2000shutdown.mp3
#   winxpstartup.mp3   / winxpshutdown.mp3
#   winvistastartup.mp3 / winvistashutdown.mp3
#   win11startup.mp3   / win11shutdown.mp3

set -euo pipefail

SOUND_DIR="$HOME/.config/omarchy/sounds"
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Omarchy Sounds" "$1" || true
}

mkdir -p "$SOUND_DIR" "$STATE_DIR"

options=$'Windows 2000\nWindows XP\nWindows Vista\nWindows 11'

choice="$(printf '%s\n' "$options" | omarchy-launch-walker --dmenu --width 360 --minheight 1 --maxheight 300 -p "Sound theme…" 2>/dev/null || true)"
[[ -z "${choice:-}" || "$choice" == "CNCLD" ]] && exit 0

case "$choice" in
  "Windows 2000")
    startup_src="$SOUND_DIR/win2000startup.mp3"
    shutdown_src="$SOUND_DIR/win2000shutdown.mp3"
    ;;
  "Windows XP")
    startup_src="$SOUND_DIR/winxpstartup.mp3"
    shutdown_src="$SOUND_DIR/winxpshutdown.mp3"
    ;;
  "Windows Vista")
    startup_src="$SOUND_DIR/winvistastartup.mp3"
    shutdown_src="$SOUND_DIR/winvistashutdown.mp3"
    ;;
  "Windows 11")
    startup_src="$SOUND_DIR/win11startup.mp3"
    shutdown_src="$SOUND_DIR/win11shutdown.mp3"
    ;;
  *)
    notify "Unknown selection: $choice"
    exit 1
    ;;
esac

if [[ ! -f "$startup_src" ]]; then
  notify "Missing file: $(basename "$startup_src")"
  echo "Missing: $startup_src" >&2
  exit 1
fi

if [[ ! -f "$shutdown_src" ]]; then
  notify "Missing file: $(basename "$shutdown_src")"
  echo "Missing: $shutdown_src" >&2
  exit 1
fi

cp -f "$startup_src"  "$SOUND_DIR/startup.mp3"
cp -f "$shutdown_src" "$SOUND_DIR/shutdown.mp3"
echo "$choice" > "$CURRENT_FILE"

notify "Sound theme set to: $choice ✅"

echo "Sound theme set to: $choice ✅"
echo
echo "startup.mp3  <- $(basename "$startup_src")"
echo "shutdown.mp3 <- $(basename "$shutdown_src")"
echo
read -n 1 -r -s -p "Press any key to close…"
echo
