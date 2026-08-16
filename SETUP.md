# Setup Guide

Step-by-step instructions for installing these customizations on a fresh Omarchy system.

---

## 1. Install Prerequisites

```bash
sudo pacman -S wireguard-tools nfs-utils jq rofi mpv python-reportlab fastfetch zathura libnotify
```

Install PIA via the AUR (provides `piactl` at `/opt/piavpn/bin/piactl`):

```bash
omarchy-pkg-aur-add piavpn-bin
```

> `piavpn-bin` is the [AUR package](https://aur.archlinux.org/packages/piavpn-bin) for the official PIA Linux client.
# Waybar was retired by Omarchy Quattro. The bar is now omarchy-shell, and the
# VPN widget installs as a plugin:
#   omarchy plugin add https://github.com/Paulie420/omarchy-vpn.git --enable

---

## 2. WireGuard / PiVPN Setup

> Migrated from OpenVPN in May 2026. OpenVPN dropped every 5–6 minutes from remote
> networks because its sessions expire when NAT tables time out; WireGuard is
> stateless and reconnects sub-second. The legacy `openvpn/pivpn.conf.template`
> remains in this repo for reference only.

### 2a. Generate the client on the server

On the PiVPN server, `pivpn -a` creates a client and prints its config. Copy that
to the laptop as `/etc/wireguard/pivpn.conf`:

```bash
sudo install -m 600 /dev/stdin /etc/wireguard/pivpn.conf <<'EOF'
[Interface]
PrivateKey = <client private key>
Address = 10.138.26.2/24,fd11:5ee:bad:c0de::a8a:1a02/64

[Peer]
PublicKey = <server public key>
PresharedKey = <preshared key>
Endpoint = <home-public-ip-or-ddns>:51820
AllowedIPs = 10.0.0.0/24, 10.138.26.0/24
PersistentKeepalive = 25
EOF
```

Key points:
- **`AllowedIPs` defines split tunnelling.** Listing only the homelab and tunnel
  subnets means internet traffic never enters the tunnel — so PIA and PiVPN can run
  together, and `curl ifconfig.me` correctly shows your real IP with only PiVPN up.
- **No `DNS =` line** — it conflicts with openresolv/systemd-resolved on Arch.
- **`PersistentKeepalive = 25`** keeps NAT entries warm on remote networks.
- Prefer a **DDNS hostname** over a bare IP for `Endpoint`. A residential IP will
  change eventually and every failure it causes looks identical to a dead server.

Ensure **UDP 51820** is forwarded on the home router to the PiVPN host.

### 2b. Enable the systemd service

```bash
sudo systemctl enable wg-quick@pivpn     # do NOT --now; toggle from Waybar
```

> **Note:** The unit is named after the config file: `wg-quick@pivpn` corresponds to
> `/etc/wireguard/pivpn.conf`. It is `Type=oneshot`, so it reports `active` as soon
> as the interface exists — *even if the peer never answers*. That is why the status
> script checks `rx_bytes` instead (see README, "Status indicators report real
> liveness").

### 2c. Set up polkit for passwordless control

```bash
sudo tee /etc/polkit-1/rules.d/51-wireguard-pivpn.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "wg-quick@pivpn.service" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
```

### 2d. Verify

```bash
sudo wg show pivpn                              # look for "latest handshake"
cat /sys/class/net/pivpn/statistics/rx_bytes    # >0 means the peer answered
```

---

## 3. Install Scripts

### 3a. Local bin scripts

```bash
cp local-bin/omarchy-menu ~/.local/bin/omarchy-menu
cp local-bin/pivpn-connect.sh ~/.local/bin/pivpn-connect.sh
cp local-bin/pivpn-disconnect.sh ~/.local/bin/pivpn-disconnect.sh
chmod +x ~/.local/bin/omarchy-menu
chmod +x ~/.local/bin/pivpn-*.sh
```

### 3b. Omarchy config bin scripts

```bash
mkdir -p ~/.config/omarchy/bin
cp omarchy-config/bin/* ~/.config/omarchy/bin/
chmod +x ~/.config/omarchy/bin/*.sh
chmod +x ~/.config/omarchy/bin/hypr-cheatgen.py
```

### 3c. Edit NAS configuration

Open `~/.config/omarchy/bin/nas-mount-smart.sh` and set your values:

```bash
NAS_IP="YOUR_NAS_IP"           # e.g., 192.168.1.100
EXPORT_BASE="/YOUR_NAS_EXPORT" # the NFS export root path on the NAS

MOUNTS=(
  "ShareName1:/mnt/LocalMount1"
  "ShareName2:/mnt/LocalMount2"
)
```

Do the same in `~/.config/omarchy/bin/vpn-nas-status.sh` and `~/.config/omarchy/bin/nas-unmount-all.sh`.

---

## 4. Waybar

### 4a. Install scripts

```bash
cp waybar/pia-*.sh ~/.config/waybar/
cp waybar/pivpn-*.sh ~/.config/waybar/
chmod +x ~/.config/waybar/*.sh
```

### 4b. Update your waybar config

Add the VPN modules to your `~/.config/waybar/config.jsonc`. See `waybar/config.jsonc` for the full example, or merge just the relevant sections:

- Add `"custom/pia"` and `"custom/pivpn"` to your `modules-right` array
- Add the module definitions from the `custom/pia` and `custom/pivpn` sections

### 4c. Update your waybar style

Merge the VPN-related CSS from `waybar/style.css` into your `~/.config/waybar/style.css`.

### 4d. Restart waybar

```bash
omarchy-restart-waybar
```

---

## 5. Root Crontab — no longer required

The OpenVPN-era `pivpn-watchdog.sh` ran from root's crontab every minute to restart
the service when `tun0` vanished. **It was removed in August 2026.** WireGuard has no
session loop to get stuck in, and the script referenced `tun0` and
`openvpn-client@pivpn` — neither of which exists any more — so it had been silently
doing nothing since the migration.

If you are upgrading an older install, remove the stale entry:

```bash
sudo crontab -l                 # check whether the line is still there
sudo crontab -e                 # delete the pivpn-watchdog.sh line
```

---

## 6. Startup Sound (Optional)

If you want a startup sound on login, add this to your Hyprland autostart:

```bash
# In ~/.config/hypr/autostart.conf:
exec-once = ~/.config/omarchy/bin/hypr-startup-sound.sh
```

Copy the included sound files to `~/.config/omarchy/sounds/`:

```bash
mkdir -p ~/.config/omarchy/sounds
cp sounds/*.mp3 ~/.config/omarchy/sounds/
```

The repo includes Windows 2000, XP, Vista, and 11 startup/shutdown sounds. You can also add your own MP3 files — just update `change-startup-shutdown-sounds.sh` with the new theme name and filenames.

---

## 7. Terminal MOTD (Optional)

To show a smart fastfetch display when opening a new terminal, source the script from your shell RC:

```bash
# In ~/.bashrc or ~/.zshrc (or via Omarchy shell hooks):
source ~/.config/omarchy/bin/terminal-motd.sh
```

---

## 8. Screensaver Configs (Optional)

The screensaver mode scripts swap between two hypridle configs. Create them:

```bash
# Copy your current hypridle.conf as the "stock" version
cp ~/.config/hypr/hypridle.conf ~/.config/hypr/hypridle-stock.conf

# Create a "long" version with extended timeouts
cp ~/.config/hypr/hypridle.conf ~/.config/hypr/hypridle-long.conf
# Then edit hypridle-long.conf to increase the timeout values
```

---

## Directory Reference

After setup, your files will live at:

| File | Location |
|------|---------|
| PiVPN connect/disconnect | `~/.local/bin/pivpn-{connect,disconnect}.sh` |
| PiVPN notes (authoritative) | `~/.local/bin/PIVPN-NOTES.md` |
| Custom menu shim | `~/.local/bin/omarchy-menu` |
| Custom menu logic | `~/.config/omarchy/bin/omarchy-menu-nas.sh` |
| NAS scripts | `~/.config/omarchy/bin/nas-{mount-smart,unmount-all}.sh` |
| Sound scripts | `~/.config/omarchy/bin/{hypr-startup-sound,action-with-shutdown-sound,change-startup-shutdown-sounds}.sh` |
| Screensaver scripts | `~/.config/omarchy/bin/screensaver-{stock,long}-mode.sh` |
| Cheat sheet scripts | `~/.config/omarchy/bin/{show-cheatsheet,show-cheatsheet-pdf}.sh` |
| Cheat sheet generator | `~/.config/omarchy/bin/hypr-cheatgen.py` |
| Status dashboard | `~/.config/omarchy/bin/vpn-nas-status.sh` |
| Terminal MOTD | `~/.config/omarchy/bin/terminal-motd.sh` |
| GParted fix | `~/.config/omarchy/bin/gparted-fixed.sh` |
| Waybar VPN scripts | `~/.config/waybar/pia-*.sh`, `~/.config/waybar/pivpn-*.sh` |
| WireGuard config | `/etc/wireguard/pivpn.conf` |
| WireGuard polkit rule | `/etc/polkit-1/rules.d/51-wireguard-pivpn.rules` |
| Legacy OpenVPN config | `/etc/openvpn/client/pivpn.conf` (preserved, service disabled) |
