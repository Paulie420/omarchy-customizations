#!/usr/bin/env bash
set -euo pipefail

# omarchy-window-title -- name the terminal window so these popups are identifiable
printf '\033]0;Omarchy \u00b7 VPN & NAS Status\007'

PIACTL="/opt/piavpn/bin/piactl"
PIVPN_SERVICE="wg-quick@pivpn"
NAS_IP="10.0.0.118"

MOUNTS=(
  "/mnt/Backup4TB"
  "/mnt/Backup6TB"
  "/mnt/Beers4TB"
  "/mnt/newBackupXTB"
)

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

bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'

rule() { printf '%s  %s%s\n' "$dim" "──────────────────────────────────────────────────────────" "$rst"; }

printf '\n  %sOMARCHY%s  %s·%s  %sCUSTOMIZATION STATUS%s\n' \
  "$bold" "$rst" "$dim" "$rst" "$bold" "$rst"
rule
printf '\n'

# ---- desktop --------------------------------------------------------------
printf '  %sDESKTOP%s\n' "$bold" "$rst"
printf '    %-14s %-20s %s\n' "Sounds" "$(current_sound)" \
  "startup $([[ -f "$STARTUP_MP3" ]] && echo ✅ || echo ❌)   shutdown $([[ -f "$SHUTDOWN_MP3" ]] && echo ✅ || echo ❌)"

idle_info=""
if [[ -r "$HOME/.config/omarchy/shell.json" ]]; then
  idle_info="$(python3 -c "
import json
d=json.load(open('$HOME/.config/omarchy/shell.json')).get('idle',{})
s=d.get('screensaver',0)//60; l=d.get('lock',0)//60
print(f'screensaver {s} min  ·  lock {l} min')" 2>/dev/null || true)"
fi
printf '    %-14s %-20s %s\n' "Screensaver" "$(screensaver_mode)" "$idle_info"
printf '\n'

# ---- vpn ------------------------------------------------------------------
printf '  %sVPN%s\n' "$bold" "$rst"
if [[ -x "$PIACTL" ]]; then
  printf '    %-14s %s\n' "PIA" "$("$PIACTL" get connectionstate 2>/dev/null || echo unknown)"
else
  printf '    %-14s %s\n' "PIA" "piactl not installed"
fi

if systemctl is-active --quiet "$PIVPN_SERVICE"; then
  rx="$(cat /sys/class/net/pivpn/statistics/rx_bytes 2>/dev/null || echo 0)"
  if [[ "$rx" -gt 0 ]]; then
    printf '    %-14s %-20s %s\n' "PiVPN" "Connected ✅" \
      "$(numfmt --to=iec --suffix=B "$rx" 2>/dev/null || echo "$rx B") received"
  else
    printf '    %-14s %s\n' "PiVPN" "NO HANDSHAKE ❌   interface up, peer never answered"
  fi
else
  printf '    %-14s %s\n' "PiVPN" "Disconnected"
fi
printf '\n'

# ---- nas ------------------------------------------------------------------
printf '  %sNAS%s  %s·%s  %s  %s\n' "$bold" "$rst" "$dim" "$rst" "$NAS_IP" \
  "$(ping -c1 -W1 "$NAS_IP" >/dev/null 2>&1 && echo 'reachable ✅' || echo 'unreachable ❌')"
printf '\n'
for m in "${MOUNTS[@]}"; do
  if is_mounted_mountinfo "$m"; then
    src="$(mounted_source_mountinfo "$m" || true)"
    printf '    ✅  %-22s %s%s%s\n' "$m" "$dim" "${src#*:}" "$rst"
  else
    printf '    ❌  %-22s %snot mounted%s\n' "$m" "$dim" "$rst"
  fi
done

printf '\n'
rule
printf '\n'
[[ -t 0 ]] && read -n 1 -r -s -p "  Press any key to close…"
printf '\n'
