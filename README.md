# Omarchy Linux Customizations

A collection of scripts and configuration files extending [Omarchy](https://omarchy.org/) — a beautiful, opinionated Arch Linux distribution built on Hyprland.

These customizations add:
- **Dual VPN support in Waybar** — Private Internet Access (PIA) and a self-hosted PiVPN (OpenVPN) with smart connect/disconnect logic
- **NAS mount integration** — Smart NFS mounting via local network or VPN fallback
- **Custom Omarchy menu** — Extends the built-in menu with a "Custom" section without modifying upstream files
- **Shutdown/startup sounds** — Windows-era sound themes (2000/XP/Vista/11) on boot and shutdown
- **Screensaver modes** — Toggle between stock and long-timeout hypridle configs
- **Hyprland keybind cheat sheet** — Live-generated ASCII/Markdown/PDF cheat sheet from `hyprctl`
- **Smart terminal MOTD** — Context-aware fastfetch display based on workspace/window count
- **GParted Wayland fix** — Wrapper to launch GParted correctly under Wayland/Hyprland

---

## Repository Structure

```
omarchy-customizations/
├── README.md                        # This file
├── SETUP.md                         # Installation and setup guide
├── waybar/                          # Waybar config and VPN status scripts
│   ├── config.jsonc                 # Full waybar config (includes VPN modules)
│   ├── style.css                    # Waybar stylesheet
│   ├── pia-status.sh                # PIA VPN status for waybar
│   ├── pia-toggle.sh                # Toggle PIA VPN on/off
│   ├── pia-pick-region.sh           # Pick PIA region via rofi/wofi/zenity
│   ├── pivpn-status.sh              # PiVPN (OpenVPN) status for waybar
│   └── pivpn-toggle.sh              # Toggle PiVPN on/off
├── local-bin/                       # Scripts for ~/.local/bin/
│   ├── omarchy-menu                 # Wrapper: launches custom menu shim
│   ├── pivpn-connect.sh             # Connect PiVPN (pauses PIA if running)
│   ├── pivpn-disconnect.sh          # Disconnect PiVPN (restores PIA if needed)
│   └── pivpn-watchdog.sh            # Cron watchdog: restart OpenVPN if tun0 drops
├── omarchy-config/bin/              # Scripts for ~/.config/omarchy/bin/
│   ├── omarchy-menu-nas.sh          # Custom menu shim (patches upstream menu)
│   ├── action-with-shutdown-sound.sh# Play sound before shutdown/reboot
│   ├── change-startup-shutdown-sounds.sh # Pick Windows sound theme
│   ├── hypr-cheatgen.py             # Generate Hyprland keybind cheat sheet
│   ├── hypr-startup-sound.sh        # Play startup sound on login
│   ├── nas-mount-smart.sh           # Smart NFS mount (local → PiVPN fallback)
│   ├── nas-unmount-all.sh           # Unmount all NAS shares safely
│   ├── screensaver-long-mode.sh     # Switch to long-timeout hypridle config
│   ├── screensaver-stock-mode.sh    # Switch to stock hypridle config
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
├── openvpn/
│   └── pivpn.conf.template          # OpenVPN client config template (no secrets)
└── crontab/
    └── root-crontab.example         # Root crontab for PiVPN watchdog
```

---

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| `piactl` | PIA VPN control | AUR: `omarchy-pkg-aur-add piavpn-bin` |
| `openvpn` | PiVPN tunnel | `sudo pacman -S openvpn` |
| `jq` | JSON parsing in status scripts | `sudo pacman -S jq` |
| `rofi` or `wofi` | Region picker UI | `sudo pacman -S rofi` or `sudo pacman -S wofi` |
| `mpv` / `ffplay` / `pw-play` | Sound playback | `sudo pacman -S mpv` |
| `reportlab` (Python) | PDF cheat sheet | `sudo pacman -S python-reportlab` |
| `fastfetch` | Terminal MOTD | `sudo pacman -S fastfetch` |
| `zathura` or `evince` | PDF viewer for cheat sheet | `sudo pacman -S zathura` |
| `nfs-utils` | NFS mount support | `sudo pacman -S nfs-utils` |
| `notify-send` | Desktop notifications | included with `libnotify` |

---

## Key Design Decisions

### Non-destructive menu patching
`omarchy-menu-nas.sh` is a Python-based shim that reads the upstream `omarchy-menu` script at runtime, patches it in a temp file, and executes it. This means:
- Upstream omarchy updates are automatically picked up
- No modification of files in `~/.local/share/omarchy/` (which would be overwritten by `omarchy-update`)
- The patch injects a "Custom" submenu entry before the "System" entry

### PIA ↔ PiVPN coordination
When PiVPN connects, it takes over the routing table. PIA (if running) would conflict. The connect/disconnect scripts handle this automatically:
- **Connect PiVPN**: Detects if PIA is running → disconnects it → saves state → starts OpenVPN
- **Disconnect PiVPN**: Stops OpenVPN → if PIA was running before, reconnects it

### Smart NAS mounting
`nas-mount-smart.sh` tries to mount NFS shares directly first. If the NAS is unreachable (you're away from home), it falls back to connecting PiVPN and then retrying the mount.

### Watchdog via cron
A root crontab runs `pivpn-watchdog.sh` every minute. It checks whether the `tun0` interface is present when the OpenVPN service says it's active — catching the rare case where the interface drops but the service doesn't.

---

## See Also

- [SETUP.md](SETUP.md) — step-by-step installation guide
- [Omarchy documentation](https://omarchy.org/)
- [Hyprland wiki](https://wiki.hyprland.org/)
