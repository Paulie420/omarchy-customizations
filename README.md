# Omarchy Linux Customizations

A collection of scripts and configuration files extending [Omarchy](https://omarchy.org/) — a beautiful, opinionated Arch Linux distribution built on Hyprland.

These customizations add:
- **Dual VPN support in the bar** — PIA and a self-hosted PiVPN (WireGuard). Now lives in its own published plugin: [Paulie420/omarchy-vpn](https://github.com/Paulie420/omarchy-vpn)
- **NAS mount integration** — Smart NFS mounting via local network or VPN fallback
- **Custom Omarchy menu** — Extends the built-in menu with a "Custom" section without modifying upstream files
- **Shutdown/startup sounds** — Windows-era sound themes (2000/XP/Vista/11) on boot and shutdown
- **Screensaver modes** — Toggle between stock and long idle timeouts (writes `shell.json`)
- **Hyprland keybind cheat sheet** — Live-generated ASCII/Markdown/PDF cheat sheet from `hyprctl`
- **Smart terminal MOTD** — Context-aware fastfetch display based on workspace/window count
- **GParted Wayland fix** — Wrapper to launch GParted correctly under Wayland/Hyprland

---

## Repository Structure

```
omarchy-customizations/
├── README.md                        # This file
├── SETUP.md                         # Installation and setup guide
├── hypr/                            # Hyprland config (Quattro uses Lua)
│   ├── hyprland.lua                 # entry point, requires the rest
│   ├── bindings.lua                 # personal keybinds only, 26 of 30 are now defaults
│   ├── input.lua                    # keyboard repeat, touchpad, 3-finger gesture
│   ├── looknfeel.lua                # gaps/rounding + float rule for menu popups
│   ├── autostart.lua                # startup sound
│   └── monitors.lua
├── local-bin/                       # Scripts for ~/.local/bin/
│   ├── pivpn-connect.sh             # Connect PiVPN (pauses PIA if running)
│   └── pivpn-disconnect.sh          # Disconnect PiVPN (restores PIA if needed)
├── omarchy-config/bin/              # Scripts for ~/.config/omarchy/bin/
│   ├── action-with-shutdown-sound.sh# Play sound before shutdown/reboot
│   ├── change-startup-shutdown-sounds.sh # Pick Windows sound theme
│   ├── hypr-cheatgen.py             # Generate Hyprland keybind cheat sheet
│   ├── hypr-startup-sound.sh        # Play startup sound on login
│   ├── nas-mount-smart.sh           # Smart NFS mount (local → PiVPN fallback)
│   ├── nas-unmount-all.sh           # Unmount all NAS shares safely
│   ├── screensaver-set-mode.sh      # Write idle timeouts into shell.json
│   ├── screensaver-long-mode.sh     # thin wrapper -> long profile
│   ├── screensaver-stock-mode.sh    # thin wrapper -> stock profile
│   ├── show-cheatsheet.sh           # Show keybind cheat sheet in terminal
│   ├── show-cheatsheet-pdf.sh       # Open keybind cheat sheet as PDF
│   ├── terminal-motd.sh             # Smart fastfetch MOTD for new terminals
│   ├── vpn-nas-status.sh            # Status dashboard: VPN + NAS + sounds
│   └── gparted-fixed.sh             # GParted launcher for Wayland
├── sounds/                          # Windows-era startup/shutdown sound themes
│   ├── win2000startup.mp3
│   ├── win2000shutdown.mp3
│   ├── winxpstartup.mp3
│   ├── winxpshutdown.mp3
│   ├── winvistastartup.mp3
│   ├── winvistashutdown.mp3
│   ├── win11startup.mp3
│   └── win11shutdown.mp3
└── openvpn/
    └── pivpn.conf.template          # Legacy OpenVPN template — superseded by WireGuard
```

> **Note:** This machine moved to **Omarchy Quattro (4.x)** in August 2026. Waybar,
> Walker, Mako and SwayOSD were all retired in favour of `omarchy-shell`, Hyprland
> config moved from `.conf` to `.lua`, and the custom menu became a supported
> `extensions/omarchy-menu.jsonc` file instead of a script that regex-patched the
> upstream menu at runtime. The VPN indicators became a Quickshell plugin, which
> now lives in its own repo: **[Paulie420/omarchy-vpn](https://github.com/Paulie420/omarchy-vpn)**.
>
> PiVPN migrated from OpenVPN to WireGuard in May 2026. The `openvpn/`
> template is kept for historical reference only. The old `pivpn-watchdog.sh` and
> its root crontab entry were removed in August 2026 — they watched `tun0` and
> `openvpn-client@pivpn`, neither of which exists under WireGuard.

---

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| `piactl` | PIA VPN control | AUR: `omarchy-pkg-aur-add piavpn-bin` |
| `wireguard-tools` | PiVPN tunnel (`wg`, `wg-quick`) | `sudo pacman -S wireguard-tools` |
| `jq` | JSON parsing in status scripts | `sudo pacman -S jq` |
| `omarchy-menu-select` | Option pickers (sound theme, VPN region) | ships with Omarchy Quattro |
| `mpv` / `ffplay` / `pw-play` | Sound playback | `sudo pacman -S mpv` |
| `reportlab` (Python) | PDF cheat sheet | `sudo pacman -S python-reportlab` |
| `fastfetch` | Terminal MOTD | `sudo pacman -S fastfetch` |
| `zathura` or `evince` | PDF viewer for cheat sheet | `sudo pacman -S zathura` |
| `nfs-utils` | NFS mount support | `sudo pacman -S nfs-utils` |
| `notify-send` | Desktop notifications | included with `libnotify` |

---

## Key Design Decisions

### The custom menu is now supported config, not a patch
Before Quattro this was `omarchy-menu-nas.sh`, a shim that read the upstream
`omarchy-menu` script at runtime, rewrote it with a Python regex pass, and ran
the patched copy from `/tmp`. It anchored on upstream internals, so any
restructure upstream made it silently no-op — the stock menu kept working and
the Custom submenu just vanished.

Quattro replaced all of that with `~/.config/omarchy/extensions/omarchy-menu.jsonc`:
declarative, hot-reloading on save, and immune to upstream changes. Rows use
dotted ids for nesting, `checked` to show live state with a ✓, and `when` to hide
a row whose command is missing.

### PIA ↔ PiVPN coordination
- **Connect PiVPN**: Detects if PIA is running → disconnects it → saves state → starts `wg-quick@pivpn`
- **Disconnect PiVPN**: Stops the tunnel → if PIA was running before, reconnects it

This dates from the OpenVPN era, when PiVPN took over the whole routing table.
Under WireGuard it is **belt-and-braces**: `AllowedIPs = 10.0.0.0/24, 10.138.26.0/24`
means the tunnel only claims homelab traffic and never touches internet routing, so
the two can genuinely coexist. The coordination is retained because it keeps the
routing picture simple and costs nothing.

A consequence worth knowing: with only PiVPN connected, `curl ifconfig.me` returns
your **real** IP. That is correct — split tunnelling means internet traffic never
enters the tunnel.

### Smart NAS mounting
`nas-mount-smart.sh` tries to mount NFS shares directly first. If the NAS is unreachable (you're away from home), it falls back to connecting PiVPN and then retrying the mount.

### Status indicators report real liveness, not service state
The VPN indicators moved out of this repo in August 2026 and became a published
Quickshell plugin: **[Paulie420/omarchy-vpn](https://github.com/Paulie420/omarchy-vpn)**.
They were rewritten after a multi-hour outage during which the bar showed a
confident green "Connected" the entire time.

**PiVPN.** `wg-quick@pivpn` is a `Type=oneshot` unit — it goes `active` the moment
the interface and routes exist, *without ever contacting the peer*. So
`systemctl is-active` is true for a completely dead tunnel. The plugin
instead reads `rx_bytes` from `/sys/class/net/pivpn/statistics/` (no root
required): `rx_bytes == 0` means no handshake has ever completed. It also latches
a "stale" state if inbound traffic stops for more than 240s.

**PIA.** An expired account token is indistinguishable from "switched off" if you
only look at `connectionstate`. The plugin reads PIA's own daemon log for
`ApiUnauthorizedError` and **latches** a LOGGED OUT state — cleared only by a
genuinely successful connection, since PIA stops retrying (and stops logging new
401s) once it gives up.

The plugin also drives any other VPN with a CLI (Mullvad, Proton, NordVPN, IVPN,
Mozilla, Windscribe, AirVPN, FortiVPN, or any NetworkManager profile) from
config alone — see its README.

The old cron watchdog was removed — see the note under Repository Structure.

---

## See Also

- [SETUP.md](SETUP.md) — step-by-step installation guide
- [Omarchy documentation](https://omarchy.org/)
- [Hyprland wiki](https://wiki.hyprland.org/)
