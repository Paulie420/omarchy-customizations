#!/usr/bin/env bash
# Switch to "long" hypridle configuration (extended timeouts).
# Requires: ~/.config/hypr/hypridle-long.conf to exist.
# See SETUP.md for instructions on creating the stock/long configs.

set -euo pipefail

CFG_DIR="$HOME/.config/hypr"
SRC="$CFG_DIR/hypridle-long.conf"
DST="$CFG_DIR/hypridle.conf"

STATE_DIR="$HOME/.config/omarchy/state"
MODE_FILE="$STATE_DIR/screensaver_mode"

echo "=== Screensaver: LONG mode ==="
echo "[1/3] Source:      $SRC"
echo "[1/3] Destination: $DST"
echo

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: missing $SRC"
  command -v notify-send >/dev/null 2>&1 && notify-send "Screensaver" "Missing: hypridle-long.conf" || true
  exit 1
fi

cp -f "$SRC" "$DST"
echo "[2/3] Copied long config -> hypridle.conf"

# Restart hypridle (systemd user if available, else manual)
if systemctl --user list-unit-files 2>/dev/null | rg -q '^hypridle\.service'; then
  systemctl --user restart hypridle.service
  echo "[3/3] Restarted hypridle.service (user)"
else
  pkill -x hypridle 2>/dev/null || true
  nohup hypridle -c "$DST" >/dev/null 2>&1 &
  disown || true
  echo "[3/3] Restarted hypridle (manual)"
fi

mkdir -p "$STATE_DIR"
echo "long" > "$MODE_FILE"

command -v notify-send >/dev/null 2>&1 && notify-send "Screensaver" "Long mode enabled ✅" || true
echo
read -n 1 -r -s -p "Press any key to close…"
echo
