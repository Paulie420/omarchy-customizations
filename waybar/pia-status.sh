#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C

PIACTL="/opt/piavpn/bin/piactl"

safe_get() { "$PIACTL" get "$1" 2>/dev/null | tr -d '\r' || true; }

state="$(safe_get connectionstate)"
region="$(safe_get region)"
pubip="$(safe_get pubip)"
vpnip="$(safe_get vpnip)"

if [[ "$state" == "Connected" ]]; then
  text=""; cls="active"
else
  text=""; cls="inactive"
fi

# Build tooltip with real newlines (no markup)
tip="PIA VPN: ${state:-Unknown}
Region: ${region:-auto}
Public IP: ${pubip:-unknown}
VPN IP: ${vpnip:-unknown}"

if command -v jq >/dev/null 2>&1; then
  # Use jq to JSON-escape fields so newlines render correctly
  printf '{"text":%s,"class":%s,"tooltip":%s}\n' \
    "$(printf %s "$text"  | jq -Rs .)" \
    "$(printf %s "$cls"   | jq -Rs .)" \
    "$(printf %s "$tip"   | jq -Rs .)"
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
