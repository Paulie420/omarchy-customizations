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

log "[PiVPN] Connecting…"

# 1) Handle PIA state: if PIA is running, disconnect it first and save that we did so
if [[ -x "$PIACTL" ]]; then
  state="$("$PIACTL" get connectionstate 2>/dev/null || true)"
  if [[ "$state" == "Connected" || "$state" == "Connecting" ]]; then
    log "[PiVPN] PIA is $state – disconnecting it first…"
    echo "1" > "$STATE_FILE"
    "$PIACTL" disconnect || true
    sleep 2
  else
    rm -f "$STATE_FILE"
  fi
else
  rm -f "$STATE_FILE"
fi

# 2) If PiVPN already active, bail
if systemctl is-active --quiet "$SERVICE"; then
  log "[PiVPN] $SERVICE is already active."
  exit 0
fi

# 3) Start via systemd (polkit will handle auth if needed)
log "[PiVPN] Starting $SERVICE via systemd…"
if ! systemctl start "$SERVICE"; then
  log "[PiVPN] ERROR: failed to start $SERVICE."
  exit 1
fi

log "[PiVPN] Started."
