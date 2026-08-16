#!/usr/bin/env bash
set -euo pipefail

USER_ID="$(id -u)"

exec pkexec env \
  XDG_RUNTIME_DIR="/run/user/$USER_ID" \
  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
  DISPLAY="${DISPLAY:-:0}" \
  XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}" \
  /usr/bin/gparted
