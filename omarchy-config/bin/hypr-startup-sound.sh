#!/usr/bin/env bash
set -euo pipefail

SOUND_DIR="$HOME/.config/omarchy/sounds"
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

SOUND_STARTUP="$SOUND_DIR/startup.mp3"
FALLBACK_STARTUP="$SOUND_DIR/winxpstartup.mp3"

ensure_defaults() {
  mkdir -p "$SOUND_DIR" "$STATE_DIR"

  if [[ ! -f "$CURRENT_FILE" ]]; then
    echo "Windows XP" > "$CURRENT_FILE"
  fi

  if [[ ! -f "$SOUND_STARTUP" && -f "$FALLBACK_STARTUP" ]]; then
    cp -f "$FALLBACK_STARTUP" "$SOUND_STARTUP"
  fi
}

play_sound() {
  local f="$1"

  if command -v mpv >/dev/null 2>&1; then
    mpv --no-video --really-quiet --keep-open=no "$f" >/dev/null 2>&1 || true
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$f" >/dev/null 2>&1 || true
  elif command -v pw-play >/dev/null 2>&1; then
    pw-play "$f" >/dev/null 2>&1 || true
  elif command -v paplay >/dev/null 2>&1; then
    paplay "$f" >/dev/null 2>&1 || true
  fi
}

ensure_defaults

if [[ -f "$SOUND_STARTUP" ]]; then
  play_sound "$SOUND_STARTUP"
elif [[ -f "$FALLBACK_STARTUP" ]]; then
  play_sound "$FALLBACK_STARTUP"
fi

