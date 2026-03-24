#!/usr/bin/env bash
set -euo pipefail

SERVICE="openvpn-client@pivpn"
PIACTL="/opt/piavpn/bin/piactl"
STATE_FILE="/tmp/pivpn-pia-was-connected"

log() {
  # Only print if stdout is a terminal
  if [[ -t 1 ]]; then
    echo "$@"
  fi
}

log "[PiVPN] Disconnecting…"

# 1) Stop PiVPN via systemd (polkit will handle auth if needed)
if systemctl is-active --quiet "$SERVICE"; then
  if ! systemctl stop "$SERVICE"; then
    log "[PiVPN] ERROR: failed to stop $SERVICE."
    exit 1
  fi
else
  log "[PiVPN] $SERVICE is not active."
fi

log "[PiVPN] Disconnected."

# 2) If PIA was previously connected before PiVPN, reconnect it now
if [[ -x "$PIACTL" && -f "$STATE_FILE" ]]; then
  log "[PiVPN] PIA was connected before PiVPN. Reconnecting PIA…"
  "$PIACTL" connect || true
  rm -f "$STATE_FILE"
fi
