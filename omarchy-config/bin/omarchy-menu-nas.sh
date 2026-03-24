#!/usr/bin/env bash
# Custom Omarchy menu shim
#
# This script patches the upstream omarchy-menu at runtime (in a temp file)
# to inject a "Custom" submenu — without modifying any files in
# ~/.local/share/omarchy/ (which would be overwritten by omarchy-update).
#
# How it works:
#   1. Reads the upstream omarchy-menu script
#   2. Uses Python regex to inject a "Custom" entry before "System" in the
#      main menu, route it in go_to_menu(), and inject show_custom_menu()
#   3. Also wraps shutdown/reboot calls to play a sound first
#   4. Writes the patched script to a temp file and exec's it
#
# Place at: ~/.config/omarchy/bin/omarchy-menu-nas.sh
# Invoked by: ~/.local/bin/omarchy-menu (which overrides the upstream command)

set -euo pipefail

UPSTREAM="$HOME/.local/share/omarchy/bin/omarchy-menu"
PATCHED="$(mktemp /tmp/omarchy-menu.patched.XXXXXX)"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Omarchy Custom Menu" "$1" || true
}

if [[ ! -r "$UPSTREAM" ]]; then
  notify "Can't read upstream menu: $UPSTREAM"
  exit 1
fi

python3 - <<'PY' "$UPSTREAM" "$PATCHED"
import sys, re

src_path, out_path = sys.argv[1], sys.argv[2]
s = open(src_path, "r", encoding="utf-8").read()

CUSTOM_LABEL = "󰠱  Custom"

ACTION = '"$HOME/.config/omarchy/bin/action-with-shutdown-sound.sh"'
SOUND_PICKER = '"$HOME/.config/omarchy/bin/change-startup-shutdown-sounds.sh"'

# -----------------------------
# 1) Add Custom to main menu list (just above System)
# -----------------------------
main_menu_pat = r'(show_main_menu\(\)\s*\{\s*\n\s*go_to_menu "\$\(\s*menu "Go" "\s*)([^"]+)("\s*\)\s*"\s*\n\s*\}\s*)'
m = re.search(main_menu_pat, s, re.S)

if not m:
  open(out_path, "w", encoding="utf-8").write(s)
  sys.exit(0)

options = m.group(2)

if ("Custom" not in options) and (CUSTOM_LABEL not in options):
  items = options.split("\\n")
  items = [x for x in items if ("Custom" not in x and x != CUSTOM_LABEL)]

  sys_idx = None
  for i, it in enumerate(items):
    if "System" in it:
      sys_idx = i
      break

  if sys_idx is None:
    items.append(CUSTOM_LABEL)
  else:
    items.insert(sys_idx, CUSTOM_LABEL)

  options = "\\n".join(items)

s = s[:m.start(2)] + options + s[m.end(2):]

# -----------------------------
# 2) Route in go_to_menu()
# -----------------------------
if "show_custom_menu" not in s:
  if "*trigger*) show_trigger_menu ;;" in s:
    s = s.replace(
      "*trigger*) show_trigger_menu ;;",
      "*trigger*) show_trigger_menu ;;\n  *custom*) show_custom_menu ;;"
    )

# -----------------------------
# 3) Inject show_custom_menu()
# -----------------------------
if "show_custom_menu()" not in s:
  inject_after = "show_trigger_menu() {"
  idx = s.find(inject_after)
  if idx != -1:
    insert_point = s.find("}\n\n", idx)
    if insert_point != -1:
      custom_fn = r'''

show_custom_menu() {
  case $(menu "Custom" "🗄  Mount NAS (smart)\n🧹  Unmount NAS\n📁  Open /mnt (choose mount)\n──────── VPN ────────\n🛡  PIA Connect\n🚫  PIA Disconnect\n🔒  PiVPN Connect\n🔓  PiVPN Disconnect\n────── Cheatsheets ──────\n📄  Show Binds (TXT)\n🖼  Show Binds (PDF)\n────── Screensaver ──────\n󰖨  Screensaver Stock Mode\n󰖨  Screensaver Long Mode\n────── Sounds ──────\n🎵  Change Startup/Shutdown Sounds\n──────── Status ────────\nℹ  Customization Status") in

    *"Mount NAS"*)
      present_terminal "$HOME/.config/omarchy/bin/nas-mount-smart.sh"
      ;;

    *"Unmount NAS"*)
      present_terminal "$HOME/.config/omarchy/bin/nas-unmount-all.sh"
      ;;

    *"Open /mnt"*)
      setsid nautilus /mnt >/dev/null 2>&1 &
      disown
      ;;

    *"PIA Connect"*)
      present_terminal "bash -lc '/opt/piavpn/bin/piactl connect || true; /opt/piavpn/bin/piactl get connectionstate || true; echo; read -n 1 -r -s -p \"Press any key…\"'"
      ;;

    *"PIA Disconnect"*)
      present_terminal "bash -lc '/opt/piavpn/bin/piactl disconnect || true; /opt/piavpn/bin/piactl get connectionstate || true; echo; read -n 1 -r -s -p \"Press any key…\"'"
      ;;

    *"PiVPN Connect"*)
      present_terminal "$HOME/.local/bin/pivpn-connect.sh"
      ;;

    *"PiVPN Disconnect"*)
      present_terminal "$HOME/.local/bin/pivpn-disconnect.sh"
      ;;

    *"Show Binds (TXT)"*)
      present_terminal "$HOME/.config/omarchy/bin/show-cheatsheet.sh --all"
      ;;

    *"Show Binds (PDF)"*)
      bash -lc "$HOME/.config/omarchy/bin/show-cheatsheet-pdf.sh --all" >/dev/null 2>&1 &
      ;;

    *"Screensaver Stock Mode"*)
      present_terminal "$HOME/.config/omarchy/bin/screensaver-stock-mode.sh"
      ;;

    *"Screensaver Long Mode"*)
      present_terminal "$HOME/.config/omarchy/bin/screensaver-long-mode.sh"
      ;;

    *"Change Startup/Shutdown Sounds"*)
      present_terminal ''' + SOUND_PICKER + r'''
      ;;

    *"Customization Status"*)
      present_terminal "$HOME/.config/omarchy/bin/vpn-nas-status.sh"
      ;;

    *"────"*|*"────────"*)
      show_custom_menu
      ;;

    *)
      show_main_menu
      ;;
  esac
}
'''
      s = s[:insert_point+3] + custom_fn + s[insert_point+3:]

# -----------------------------
# 4) Wrap Omarchy System menu shutdown/reboot tokens
# -----------------------------
def wrap_token(token: str, replacement: str):
  global s
  pat = rf'(?<!{re.escape("action-with-shutdown-sound.sh")} )\b{re.escape(token)}\b'
  s = re.sub(pat, replacement, s)

wrap_token("omarchy-cmd-shutdown", f"{ACTION} shutdown")
wrap_token("omarchy-cmd-reboot",   f"{ACTION} reboot")

# -----------------------------
# 5) Safety net: wrap any systemctl poweroff/reboot/halt
# -----------------------------
def wrap_cmd(pattern, repl):
  global s
  s = re.sub(pattern, repl, s, flags=re.M)

wrap_cmd(
  rf'(^|[;&\(\)\n]\s*)(?!{re.escape(ACTION)}\s+--\s+)((?:/usr/bin/)?systemctl\b[^\n;&\)]*\b(?:poweroff|reboot|halt)\b[^\n;&\)]*)',
  rf'\1{ACTION} -- \2'
)

if "OMARCHY_CUSTOM_PATCH_MARKER" not in s and "show_custom_menu()" in s:
  s += "\n# OMARCHY_CUSTOM_PATCH_MARKER\n"

open(out_path, "w", encoding="utf-8").write(s)
PY

chmod +x "$PATCHED"

if grep -q "OMARCHY_CUSTOM_PATCH_MARKER" "$PATCHED"; then
  notify "Custom menu patch applied ✅"
else
  notify "Patch didn't apply (upstream changed?) — running stock menu."
fi

exec bash "$PATCHED" "$@"
