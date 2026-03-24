#!/usr/bin/env bash
# Smart terminal MOTD using fastfetch.
# - Shows system info on new terminals
# - Adapts logo display based on terminal width and window count on workspace
# - Skips if stdout is not a TTY or MOTD was already shown this session
#
# Source from ~/.bashrc or ~/.zshrc:
#   source ~/.config/omarchy/bin/terminal-motd.sh

set -euo pipefail

# If sourced, we can "return"; if executed, we must "exit".
_is_sourced() { [[ "${BASH_SOURCE[0]}" != "${0}" ]]; }
_die() { local rc="${1:-0}"; shift || true; _is_sourced && return "$rc" || exit "$rc"; }

# Only run when stdout is a TTY (real terminal)
[[ -t 1 ]] || _die 0

# Avoid re-printing inside the same terminal session
if [[ -n "${OMARCHY_MOTD_SHOWN:-}" ]]; then
  _die 0
fi
export OMARCHY_MOTD_SHOWN=1

# If fastfetch isn't available, do nothing (silent)
command -v fastfetch >/dev/null 2>&1 || _die 0

cols="$(tput cols 2>/dev/null || echo 120)"

# Always go compact if the terminal is narrow
if (( cols < 110 )); then
  fastfetch --logo none \
    --structure "title:separator:os:kernel:uptime:packages:shell:terminal:wm:cpu:memory:disk:break:localip" \
    2>/dev/null || true
  _die 0
fi

# If Hyprland JSON tools aren't available, just do "no logo"
if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  fastfetch --logo none 2>/dev/null || true
  _die 0
fi

# Give Hypr a split second to register the new client
sleep 0.05

ws_id="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' || true)"
if [[ -z "${ws_id:-}" ]]; then
  fastfetch --logo none 2>/dev/null || true
  _die 0
fi

# Count Alacritty windows on this workspace.
# NOTE: Hyprland "class" is usually "Alacritty" but sometimes it's "org.alacritty.Alacritty".
alacritty_count="$(
  hyprctl clients -j 2>/dev/null | jq --argjson ws "$ws_id" '
    [ .[]
      | select(.workspace.id == $ws)
      | select((.class // "" | ascii_downcase) | test("alacritty"))
    ] | length
  ' 2>/dev/null || echo 2
)"

# Show logo only on the first terminal in a workspace; compact on subsequent ones
if [[ "${alacritty_count:-2}" -le 1 ]]; then
  fastfetch --logo small 2>/dev/null || true
else
  fastfetch --logo none 2>/dev/null || true
fi

_die 0
