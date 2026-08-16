-- Personal keybinding overrides, ported from the pre-Quattro bindings.conf
-- (2026-08-15). Of the 30 bindings in that file, 26 are now Omarchy Quattro
-- defaults and are therefore NOT repeated here -- only genuine personal
-- bindings live below.
--
-- Quattro defaults are deliberately left alone except where noted. Check what
-- a key currently does before claiming it:  omarchy menu keybindings --print

-- ---- Keys that were unbound in stock Quattro -------------------------------

o.bind("SUPER + SHIFT + K", "Keybind cheatsheet",
  os.getenv("HOME") .. "/.config/omarchy/bin/show-cheatsheet.sh --all")

-- Moved off SUPER+ALT+K so Quattro keeps its stock "Tmux keybindings" there.
o.bind("SUPER + SHIFT + ALT + K", "Keybind cheatsheet (PDF)",
  os.getenv("HOME") .. "/.config/omarchy/bin/show-cheatsheet-pdf.sh --all")

o.bind("SUPER + SHIFT + T", "Activity (btop)", "omarchy-launch-tui btop")

o.bind("SUPER + ALT + E", "Emote picker", "emote")

-- Moved off SUPER+SHIFT+W so Quattro keeps its stock "Omawrite" there.
o.bind("SUPER + ALT + W", "Typora", "uwsm-app -- typora")

-- ---- The one Quattro default we deliberately displace -----------------------
-- Was: Google Maps. SyncTERM is the BBS client and earns the shorter key.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "SyncTERM (BBS)", "uwsm-app -- syncterm")
