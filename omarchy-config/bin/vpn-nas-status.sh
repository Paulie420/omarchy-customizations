#!/usr/bin/env bash
# Status dashboard: shows VPN state, NAS reachability, mount status,
# sound theme, and screensaver mode.
# Edit NAS_IP and MOUNTS to match your configuration.

set -euo pipefail

PIACTL="/opt/piavpn/bin/piactl"
PIVPN_SERVICE="openvpn-client@pivpn"

# ── CONFIGURE THESE ──────────────────────────────────────────────────────────
NAS_IP="YOUR_NAS_IP"               # e.g., 192.168.1.100
MOUNTS=(
  "/mnt/Share1"
  "/mnt/Share2"
  "/mnt/Share3"
)
# ─────────────────────────────────────────────────────────────────────────────

SOUND_DIR="$HOME/.config/omarchy/sounds"
STATE_DIR="$HOME/.config/omarchy/state"
MODE_FILE="$STATE_DIR/screensaver_mode"
CURRENT_SOUND_FILE="$STATE_DIR/current_sound"
STARTUP_MP3="$SOUND_DIR/startup.mp3"
SHUTDOWN_MP3="$SOUND_DIR/shutdown.mp3"

trap 'echo; echo "[status] interrupted"; exit 0' INT TERM

is_mounted_mountinfo() {
  local target="$1"
  awk -v t="$target" '$5==t {found=1} END{exit(found?0:1)}' /proc/self/mountinfo
}

mounted_source_mountinfo() {
  local target="$1"
  awk -v t="$target" '
    $5==t {
      for (i=1; i<=NF; i++) if ($i=="-") {dash=i; break}
      fstype=$(dash+1); source=$(dash+2);
      printf("%s %s", fstype, source);
      exit 0
    }
    END { exit 1 }
  ' /proc/self/mountinfo
}

current_sound() {
  if [[ -f "$CURRENT_SOUND_FILE" ]]; then
    head -n 1 "$CURRENT_SOUND_FILE" | tr -d '\r'
  else
    echo "Unknown (not set)"
  fi
}

screensaver_mode() {
  if [[ -f "$MODE_FILE" ]]; then
    m="$(head -n 1 "$MODE_FILE" | tr -d '\r')"
    case "$m" in
      stock) echo "Stock" ;;
      long)  echo "Long" ;;
      *)     echo "Unknown ($m)" ;;
    esac
  else
    echo "Unknown (not set)"
  fi
}

echo "=== CUSTOMIZATION STATUS ==="
echo

echo "Sounds:"
echo "  Theme: $(current_sound)"
echo "  Startup Sound:  $([[ -f "$STARTUP_MP3" ]] && echo "present ✅" || echo "missing ❌")"
echo "  Shutdown Sound: $([[ -f "$SHUTDOWN_MP3" ]] && echo "present ✅" || echo "missing ❌")"
echo

echo "Screensaver:"
echo "  Mode: $(screensaver_mode)"
echo


echo "PIA:"
if [[ -x "$PIACTL" ]]; then
  "$PIACTL" get connectionstate 2>/dev/null || true
else
  echo "piactl not found at $PIACTL"
fi
echo

echo "PiVPN ($PIVPN_SERVICE):"
systemctl is-active --quiet "$PIVPN_SERVICE" && echo "active ✅" || echo "inactive ❌"
echo

echo "NAS reachability ($NAS_IP):"
if ping -c 1 -W 1 "$NAS_IP" >/dev/null 2>&1; then
  echo "reachable ✅"
else
  echo "not reachable ❌"
fi
echo

echo "Mountpoints (from /proc/self/mountinfo — safe even if NFS is dead):"
for m in "${MOUNTS[@]}"; do
  if is_mounted_mountinfo "$m"; then
    src="$(mounted_source_mountinfo "$m" || true)"
    [[ -n "$src" ]] && echo "✅ $m   ($src)" || echo "✅ $m"
  else
    echo "❌ $m"
  fi
done

echo
read -n 1 -r -s -p "Press any key to close…"
echo
