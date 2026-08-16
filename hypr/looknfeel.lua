-- Personal look'n'feel overrides, ported from the pre-Quattro looknfeel.conf.
-- Tight, near-edge-to-edge tiling with slightly rounded corners.

hl.config({
  general = {
    gaps_in = 1,
    gaps_out = 0,
  },
  decoration = {
    rounding = 4,
  },
})

-- Custom menu actions (NAS mount, screensaver mode, VPN status, cheatsheet...)
-- open floating and centered instead of tiling in beside whatever is already
-- on the workspace. They are short-lived dialogs, not windows you work in.
--
-- Everything launched via `omarchy-launch-tui --app-id=org.omarchy.custom-tui`
-- matches, so one rule covers every entry in
-- ~/.config/omarchy/extensions/omarchy-menu.jsonc.
o.window("org.omarchy.custom-tui", {
  float = true,
  center = true,
  -- Explicit pixels: the "70% 70%" form was accepted but never applied, and
  -- the terminal fell back to its own 700x500. The status readout is 15 lines
  -- x 67 cols, so this leaves comfortable margin.
  size = "900 620",
})
