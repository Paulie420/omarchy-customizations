#!/usr/bin/env bash

set -euo pipefail
PIACTL="/opt/piavpn/bin/piactl"

# Make sure daemon can run headless
$PIACTL background enable >/dev/null 2>&1

state="$($PIACTL get connectionstate 2>/dev/null)"
if [[ "$state" == "Connected" || "$state" == "Connecting" ]]; then
  $PIACTL disconnect
else
  $PIACTL connect
fi
