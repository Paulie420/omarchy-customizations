#!/usr/bin/env bash
# Play a shutdown/reboot sound before executing a system power action.
# Usage:
#   action-with-shutdown-sound.sh shutdown
#   action-with-shutdown-sound.sh reboot
#   action-with-shutdown-sound.sh halt
#   action-with-shutdown-sound.sh -- <any-command>

set -euo pipefail

SOUND_DIR="$HOME/.config/omarchy/sounds"
STATE_DIR="$HOME/.config/omarchy/state"
CURRENT_FILE="$STATE_DIR/current_sound"

# Active sound (set by change-startup-shutdown-sounds.sh)
SOUND_SHUTDOWN="$SOUND_DIR/shutdown.mp3"

# Fallback if user hasn't selected a theme yet
FALLBACK_SHUTDOWN="$SOUND_DIR/winxpshutdown.mp3"

ensure_defaults() {
  mkdir -p "$SOUND_DIR" "$STATE_DIR"

  if [[ ! -f "$CURRENT_FILE" ]]; then
    echo "Windows XP" > "$CURRENT_FILE"
  fi

  # If shutdown.mp3 not present, seed it from fallback if available
  if [[ ! -f "$SOUND_SHUTDOWN" && -f "$FALLBACK_SHUTDOWN" ]]; then
    cp -f "$FALLBACK_SHUTDOWN" "$SOUND_SHUTDOWN"
  fi
}

play_sound() {
  local f="$1"

  # Blocking play (important — must finish before system shuts down)
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

SOUND_TO_PLAY=""
if [[ -f "$SOUND_SHUTDOWN" ]]; then
  SOUND_TO_PLAY="$SOUND_SHUTDOWN"
elif [[ -f "$FALLBACK_SHUTDOWN" ]]; then
  SOUND_TO_PLAY="$FALLBACK_SHUTDOWN"
fi

case "${1-}" in
  shutdown)
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec systemctl poweroff
    ;;
  reboot)
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec systemctl reboot
    ;;
  halt)
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec systemctl halt
    ;;
  --)
    shift
    [[ -n "$SOUND_TO_PLAY" ]] && play_sound "$SOUND_TO_PLAY"
    exec "$@"
    ;;
  *)
    echo "Usage: $0 {shutdown|reboot|halt|-- <command...>}" >&2
    exit 2
    ;;
esac
