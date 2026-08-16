#!/usr/bin/env bash
set -euo pipefail

# omarchy-window-title -- name the terminal window so these popups are identifiable
printf '\033]0;Omarchy \u00b7 PiVPN Connect\007'

INTERFACE="pivpn"
STATE_FILE="/tmp/pivpn-pia-was-active"

log() { if [[ -t 1 ]]; then echo "$@"; fi }

if systemctl is-active --quiet "wg-quick@${INTERFACE}.service"; then
    log "[PiVPN] Already connected."
    exit 0
fi

# Disconnect PIA if active — two VPNs routing simultaneously is unreliable
PIA_STATE=$(piactl get connectionstate 2>/dev/null || echo "Disconnected")
if [[ "$PIA_STATE" != "Disconnected" ]]; then
    log "[PiVPN] PIA is active ($PIA_STATE) — disconnecting PIA first..."
    echo "true" > "$STATE_FILE"
    piactl disconnect
    # Wait up to 10s for PIA to fully disconnect
    for i in {1..10}; do
        sleep 1
        PIA_NOW=$(piactl get connectionstate 2>/dev/null || echo "Disconnected")
        [[ "$PIA_NOW" == "Disconnected" ]] && break
    done
else
    echo "false" > "$STATE_FILE"
fi

log "[PiVPN] Connecting..."
if ! systemctl start "wg-quick@${INTERFACE}.service"; then
    log "[PiVPN] ERROR: failed to start wg-quick@${INTERFACE}."
    # Restore PIA if we turned it off
    if [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "true" ]]; then
        log "[PiVPN] Restoring PIA..."
        piactl connect || true
    fi
    exit 1
fi
log "[PiVPN] Connected."
