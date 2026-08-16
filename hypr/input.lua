-- Personal input overrides, ported from the pre-Quattro input.conf (2026-08-15).

hl.config({
  input = {
    -- Caps Lock acts as Compose.
    kb_options = "compose:caps",

    -- Faster than stock: quicker repeat, shorter delay before it kicks in.
    repeat_rate = 70,
    repeat_delay = 280,

    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 1.0,
      -- tap-to-click was set explicitly in the old .conf, but it is already
      -- Hyprland's default and the Lua config rejects the key, so it is omitted.
    },
  },
})

-- App-specific touchpad scroll speeds. Terminals scroll too slowly at the
-- default factor; Ghostty scrolls far too fast.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Three-finger horizontal swipe changes workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
