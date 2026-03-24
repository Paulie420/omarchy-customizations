#!/usr/bin/env bash
# Smart NAS mounter.
# Strategy:
#   1. Try to mount NFS shares directly (local network path)
#   2. If local mount fails, connect PiVPN and retry over the tunnel
#
# Edit the variables below for your NAS configuration before use.

set -euo pipefail

echo "=== nas-mount-smart: $(date) ==="

# ── CONFIGURE THESE ──────────────────────────────────────────────────────────
NAS_IP="YOUR_NAS_IP"               # e.g., 192.168.1.100
EXPORT_BASE="/YOUR_NAS_EXPORT_BASE" # NFS export root path on the NAS, e.g. /mnt/Data

# Format: "ExportSubdir:/local/mountpoint"
MOUNTS=(
  "Share1:/mnt/Share1"
  "Share2:/mnt/Share2"
  "Share3:/mnt/Share3"
)
# ─────────────────────────────────────────────────────────────────────────────

PIVPN_CONNECT="$HOME/.local/bin/pivpn-connect.sh"

# ── helpers ──────────────────────────────────────────────────────────────────

log(){ echo "[nas] $*"; }

have(){ command -v "$1" >/dev/null 2>&1; }

is_mounted() {
  # Safe mount check (won't hang on dead NFS)
  local target="$1"
  awk -v t="$target" '$5==t {found=1} END{exit(found?0:1)}' /proc/self/mountinfo
}

nas_port_open() {
  # Test NFS port (2049) rather than relying on ping alone
  if have nc; then
    nc -z -w1 "$NAS_IP" 2049 >/dev/null 2>&1
  else
    timeout 1 bash -lc "cat < /dev/null > /dev/tcp/$NAS_IP/2049" >/dev/null 2>&1
  fi
}

nas_reachable() {
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

  # Timeout so we never hang forever if routing is broken
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

# ── main ─────────────────────────────────────────────────────────────────────

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

log "Waiting for openvpn-client@pivpn to be active..."
for _ in $(seq 1 15); do
  systemctl is-active --quiet openvpn-client@pivpn && break
  sleep 1
done

if ! systemctl is-active --quiet openvpn-client@pivpn; then
  log "ERROR: PiVPN did not become active."
  notify-send "NAS" "PiVPN failed ❌"
  exit 1
fi

if ! wait_for_nas; then
  log "ERROR: NAS still not reachable over PiVPN (check routes/NAS IP/VPN config)"
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
