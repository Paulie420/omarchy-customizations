#!/bin/bash
set -euo pipefail

# omarchy-window-title -- name the terminal window so these popups are identifiable
printf '\033]0;Omarchy \u00b7 NAS Unmount\007'

# Unmount all NAS shares safely (won't hang on dead NFS)
MOUNTS=(/mnt/Backup4TB /mnt/Backup6TB /mnt/Beers4TB /mnt/newBackupXTB)

is_mounted() {
  awk -v t="$1" '$5==t {found=1} END{exit(found?0:1)}' /proc/self/mountinfo
}

unmounted=0
for m in "${MOUNTS[@]}"; do
  if is_mounted "$m"; then
    echo "Unmounting $m ..."
    sudo umount -l "$m" && unmounted=$((unmounted + 1)) || echo "  Failed: $m"
  else
    echo "Not mounted:  $m"
  fi
done

echo
echo "Unmounted $unmounted share(s)."
notify-send "NAS" "Unmount done ✅ ($unmounted share(s))"

# Keep the window up so the result is readable. Without this the terminal
# closed the instant the script ended, leaving only the sudo/fingerprint
# dialog on screen with nothing explaining what it was for.
[[ -t 0 ]] && { echo; read -n 1 -r -s -p "Press any key to close…"; echo; }
