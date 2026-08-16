#!/usr/bin/env bash
set -euo pipefail

# omarchy-window-title -- name the terminal window so these popups are identifiable
printf '\033]0;Omarchy \u00b7 PiVPN Disconnect\007'

INTERFACE="pivpn"
STATE_FILE="/tmp/pivpn-pia-was-active"

log() { if [[ -t 1 ]]; then echo "$@"; fi }

if systemctl is-active --quiet "wg-quick@${INTERFACE}.service"; then
    log "[PiVPN] Disconnecting..."
    if ! systemctl stop "wg-quick@${INTERFACE}.service"; then
        log "[PiVPN] ERROR: failed to stop wg-quick@${INTERFACE}."
        exit 1
    fi
    log "[PiVPN] Disconnected."
else
    log "[PiVPN] Not connected."
fi

# Restore PIA if it was active before Pi-VPN connected
if [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "true" ]]; then
    log "[PiVPN] Restoring PIA VPN..."
    piactl connect || true
    rm -f "$STATE_FILE"
fi
