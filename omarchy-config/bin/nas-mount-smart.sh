#!/usr/bin/env bash
set -euo pipefail

# omarchy-window-title -- name the terminal window so these popups are identifiable
printf '\033]0;Omarchy \u00b7 NAS Mount\007'

echo "=== nas-mount-smart: $(date) ==="

NAS_IP="10.0.0.118"
EXPORT_BASE="/mnt/SpeakerOffice"

# Mounts to create
MOUNTS=(
  "Backup4TB:/mnt/Backup4TB"
  "Backup6TB:/mnt/Backup6TB"
  "Beers4TB:/mnt/Beers4TB"
  "newBackupXTB:/mnt/newBackupXTB"
)

# Scripts you already have
PIVPN_CONNECT="$HOME/.local/bin/pivpn-connect.sh"

# ---- helpers -------------------------------------------------------------

log(){ echo "[nas] $*"; }

have(){ command -v "$1" >/dev/null 2>&1; }

is_mounted() {
  # SAFE mount check (won’t hang on dead NFS)
  local target="$1"
  awk -v t="$target" '$5==t {found=1} END{exit(found?0:1)}' /proc/self/mountinfo
}

nas_port_open() {
  # Don’t rely only on ping; test NFS port quickly.
  # 2049 is NFSv4. This doesn’t “touch” the mountpoints.
  if have nc; then
    nc -z -w1 "$NAS_IP" 2049 >/dev/null 2>&1
  else
    timeout 1 bash -lc "cat < /dev/null > /dev/tcp/$NAS_IP/2049" >/dev/null 2>&1
  fi
}

nas_reachable() {
  # Use ping OR NFS port. Ping might be blocked; port check is better.
  ping -c 1 -W 1 "$NAS_IP" >/dev/null 2>&1 || nas_port_open
}

warm_sudo() {
  log "Warming sudo (may prompt once)..."
  sudo -v
}

mount_one() {
  local share="$1" target="$2"
  mkdir -p "$target"

  if is_mounted "$target"; then
    log "Already mounted: $target"
    return 0
  fi

  local src="${NAS_IP}:${EXPORT_BASE}/${share}"
  log "Mounting: $src -> $target"

  # IMPORTANT: timeout so we never hang forever if routing is broken
  # - Use a longer timeout if your network is slow.
  if timeout 8 sudo mount "$src" "$target"; then
    return 0
  else
    log "Mount failed (or timed out) for $target"
    return 1
  fi
}

mount_all() {
  local ok=0 total=0
  for item in "${MOUNTS[@]}"; do
    total=$((total+1))
    share="${item%%:*}"
    target="${item##*:}"
    if mount_one "$share" "$target"; then
      ok=$((ok+1))
    fi
  done
  log "Mounted $ok / $total mount(s)"
  [[ "$ok" -eq "$total" ]]
}

wait_for_nas() {
  local tries=20
  local i
  for i in $(seq 1 "$tries"); do
    if nas_reachable; then
      log "NAS is reachable ✅"
      return 0
    fi
    log "Waiting for NAS ($NAS_IP) to become reachable... ($i/$tries)"
    sleep 1
  done
  return 1
}

# ---- main ---------------------------------------------------------------

# 1) Try LOCAL mount path FIRST — no VPN changes
if nas_reachable; then
  log "NAS reachable (local path) -> attempting mount..."
else
  log "NAS not reachable right now -> still attempting a quick mount with timeouts..."
fi

warm_sudo

if mount_all; then
  notify-send "NAS" "Mounted ✅"
  exit 0
fi

# 2) If local mount failed, fall back to PiVPN path
log "Local mount failed -> falling back to PiVPN path..."
log "Connecting PiVPN..."
"$PIVPN_CONNECT" || true

log "Waiting for wg-quick@pivpn and a real handshake..."
# wg-quick is Type=oneshot: it reports "active" the moment the interface and
# routes exist, WITHOUT ever contacting the peer. So waiting on the unit alone
# would happily proceed against a dead tunnel. rx_bytes only becomes non-zero
# once the server has actually answered a handshake.
rx() { cat /sys/class/net/pivpn/statistics/rx_bytes 2>/dev/null || echo 0; }

for _ in $(seq 1 20); do
  if systemctl is-active --quiet wg-quick@pivpn && [ "$(rx)" -gt 0 ]; then
    break
  fi
  sleep 1
done

if ! systemctl is-active --quiet wg-quick@pivpn; then
  log "ERROR: wg-quick@pivpn did not start."
  notify-send "NAS" "PiVPN failed ❌"
  exit 1
fi

if [ "$(rx)" -eq 0 ]; then
  log "ERROR: pivpn interface is up but the peer never answered (no handshake)."
  log "       Check the PiVPN VM is running and UDP 51820 is forwarded."
  notify-send "NAS" "PiVPN: no handshake ❌"
  exit 1
fi

if ! wait_for_nas; then
  log "ERROR: NAS still not reachable over PiVPN (routes/NAS IP/VPN config)"
  notify-send "NAS" "NAS unreachable over PiVPN ❌"
  exit 1
fi

log "Attempting mount after PiVPN is ready..."
if mount_all; then
  notify-send "NAS" "Mounted (PiVPN) ✅"
  exit 0
fi

notify-send "NAS" "Mount failed ❌"
exit 1

