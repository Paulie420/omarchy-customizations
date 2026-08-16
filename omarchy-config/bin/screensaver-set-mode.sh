#!/usr/bin/env bash
set -euo pipefail

# Set the idle/screensaver timeout profile.
#
#   screensaver-set-mode.sh stock|long
#
# Pre-Quattro this worked by copying hypridle-stock.conf / hypridle-long.conf
# over hypridle.conf and restarting hypridle. Omarchy Quattro retired hypridle
# entirely -- idle and lock are now `idle.screensaver` and `idle.lock` in
# ~/.config/omarchy/shell.json, handled inside omarchy-shell. The old scripts
# kept editing a file nothing reads, so switching modes silently did nothing.
#
# shell.json hot-reloads on save, so no restart is needed.

MODE="${1:-}"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
STATE_DIR="$HOME/.config/omarchy/state"
MODE_FILE="$STATE_DIR/screensaver_mode"

case "$MODE" in
  stock) SCREENSAVER=150; LOCK=300;  LABEL="Stock" ;;
  long)  SCREENSAVER=600; LOCK=900;  LABEL="Long"  ;;
  *) echo "usage: $(basename "$0") stock|long" >&2; exit 2 ;;
esac

printf '\033]0;Omarchy · Screensaver: %s\007' "$LABEL"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "Screensaver" "$1" || true; }

echo "=== Screensaver: ${LABEL^^} mode ==="
echo "  screensaver after : ${SCREENSAVER}s ($((SCREENSAVER / 60)) min)"
echo "  lock after        : ${LOCK}s ($((LOCK / 60)) min)"
echo

if [[ ! -f "$SHELL_JSON" ]]; then
  echo "ERROR: $SHELL_JSON not found" >&2
  notify "shell.json not found ❌"
  exit 1
fi

cp -f "$SHELL_JSON" "$SHELL_JSON.bak"

python3 - "$SHELL_JSON" "$SCREENSAVER" "$LOCK" <<'PY'
import json, sys
path, screensaver, lock = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)
cfg.setdefault("idle", {})
cfg["idle"]["screensaver"] = screensaver
cfg["idle"]["lock"] = lock
with open(path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=2)
    fh.write("\n")
print("  updated idle block in shell.json")
PY

mkdir -p "$STATE_DIR"
echo "$MODE" > "$MODE_FILE"

echo
echo "Done. omarchy-shell picks this up on save -- no restart needed."
notify "${LABEL} mode enabled ✅"

[[ -t 0 ]] && { echo; read -n 1 -r -s -p "Press any key to close…"; echo; }
