#!/usr/bin/env bash

set -euo pipefail
PIACTL="/opt/piavpn/bin/piactl"

regions="$($PIACTL get regions 2>/dev/null | tr ' ' '\n' | sed '/^$/d')"
[ -z "$regions" ] && notify-send "PIA" "No regions yet. Try: piactl login" && exit 1

# pick with rofi/wofi, fallback to zenity
if command -v rofi >/dev/null; then
  choice="$(echo "$regions" | rofi -dmenu -p 'PIA region')"
elif command -v wofi >/dev/null; then
  choice="$(echo "$regions" | wofi --dmenu -p 'PIA region')"
elif command -v zenity >/dev/null; then
  choice="$(echo "$regions" | zenity --list --column=Region)"
else
  notify-send "PIA" "Install rofi/wofi/zenity to pick regions."
  exit 1
fi

[ -z "$choice" ] && exit 0

$PIACTL set region "$choice" && notify-send "PIA" "Region set: $choice"
