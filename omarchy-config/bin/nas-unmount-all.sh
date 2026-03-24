#!/bin/bash
# Unmount all NAS shares safely (won't hang on dead NFS).
# Edit MOUNTS to match your mountpoints.

set -euo pipefail

# ── CONFIGURE THESE ──────────────────────────────────────────────────────────
MOUNTS=(/mnt/YOUR_SHARE1 /mnt/YOUR_SHARE2 /mnt/YOUR_SHARE3)  # must match nas-mount-smart.sh
# ─────────────────────────────────────────────────────────────────────────────

is_mounted() {
  awk -v t="$1" '$5==t {found=1} END{exit(found?0:1)}' /proc/self/mountinfo
}

for m in "${MOUNTS[@]}"; do
  is_mounted "$m" && sudo umount -l "$m" || true
done

notify-send "NAS" "Unmount done ✅"
