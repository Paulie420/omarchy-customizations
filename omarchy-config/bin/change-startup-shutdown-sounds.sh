#!/usr/bin/env bash
set -euo pipefail

# omarchy-window-title -- name the terminal window so these popups are identifiable
printf '\033]0;Omarchy \u00b7 Startup Sounds\007'

SOUND_DIR="$HOME/.config/omarchy/sounds"
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Omarchy Sounds" "$1" || true
}

mkdir -p "$SOUND_DIR" "$STATE_DIR"

# Quattro removed the `omarchy-launch-walker` wrapper (walker itself is retired),
# so the old dmenu call failed silently -- `|| true` swallowed it, $choice came
# back empty, and the script exited without ever showing a picker.
# `omarchy-menu-select` is Quattro's native, themed replacement.
choice="$(omarchy-menu-select "Sound theme" \
  "Windows 2000" "Windows XP" "Windows Vista" "Windows 11" 2>/dev/null || true)"
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
[[ -t 0 ]] && read -n 1 -r -s -p "Press any key to close…"
echo

