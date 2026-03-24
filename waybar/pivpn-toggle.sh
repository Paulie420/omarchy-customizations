#!/usr/bin/env bash
set -euo pipefail

SERVICE="openvpn-client@pivpn"

if systemctl is-active --quiet "$SERVICE"; then
  # PiVPN is ON → disconnect (and maybe restore PIA)
  ~/.local/bin/pivpn-disconnect.sh >/dev/null 2>&1
else
  # PiVPN is OFF → connect (and maybe drop PIA)
  ~/.local/bin/pivpn-connect.sh >/dev/null 2>&1
fi
