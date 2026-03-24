#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C

SERVICE="openvpn-client@pivpn"

# Figure out if the PiVPN systemd service is active
if systemctl is-active --quiet "$SERVICE"; then
  state="Connected"
  text=""
  cls="active"
else
  state="Disconnected"
  text=""
  cls="inactive"
fi

# Try to detect tun interface + VPN IP
tun_if="$(ip -o link show | awk -F': ' '/tun[0-9]+/ {print $2; exit}' 2>/dev/null || true)"
vpn_ip=""
if [[ -n "${tun_if:-}" ]]; then
  vpn_ip="$(ip -o -4 addr show "$tun_if" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)"
fi

# Build tooltip with real newlines (no markup)
tip="PiVPN: ${state:-Unknown}
Interface: ${tun_if:-none}
VPN IP: ${vpn_ip:-unknown}"

if command -v jq >/dev/null 2>&1; then
  # Use jq to JSON-escape fields so newlines render correctly
  printf '{"text":%s,"class":%s,"tooltip":%s}\n' \
    "$(printf %s "$text" | jq -Rs .)" \
    "$(printf %s "$cls"  | jq -Rs .)" \
    "$(printf %s "$tip"  | jq -Rs .)"
else
  # Fallback escaper if jq isn't available
  esc() {
    local s=${1//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    printf '%s' "$s"
  }
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$(esc "$text")" "$(esc "$cls")" "$(esc "$tip")"
fi
