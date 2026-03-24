# Setup Guide

Step-by-step instructions for installing these customizations on a fresh Omarchy system.

---

## 1. Install Prerequisites

```bash
sudo pacman -S openvpn nfs-utils jq rofi mpv python-reportlab fastfetch zathura libnotify
```

Install PIA via the AUR (provides `piactl` at `/opt/piavpn/bin/piactl`):

```bash
omarchy-pkg-aur-add piavpn-bin
```

> `piavpn-bin` is the [AUR package](https://aur.archlinux.org/packages/piavpn-bin) for the official PIA Linux client.
> After install, launch PIA once and log in before the waybar scripts will work.

---

## 2. OpenVPN / PiVPN Setup

### 2a. Create the client config

```bash
sudo mkdir -p /etc/openvpn/client
sudo cp openvpn/pivpn.conf.template /etc/openvpn/client/pivpn.conf
```

Edit `/etc/openvpn/client/pivpn.conf` and fill in:
- Your VPN server's IP/hostname on the `remote` line
- Your CA certificate in `<ca>` block
- Your client certificate in `<cert>` block
- Your client private key in `<key>` block
- Your TLS crypt key in `<tls-crypt>` block

### 2b. Create the password file

```bash
sudo nano /etc/openvpn/client/pivpn.askpass
# Enter your private key passphrase, save the file
sudo chmod 600 /etc/openvpn/client/pivpn.askpass
```

### 2c. Enable the systemd service

```bash
sudo systemctl enable openvpn-client@pivpn
```

> **Note:** The service is named after the config file: `openvpn-client@pivpn` corresponds to `/etc/openvpn/client/pivpn.conf`.

### 2d. Set up polkit for passwordless control

To allow your user to start/stop the VPN without a sudo prompt, create a polkit rule:

```bash
sudo tee /etc/polkit-1/rules.d/49-openvpn.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "openvpn-client@pivpn.service" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
```

---

## 3. Install Scripts

### 3a. Local bin scripts

```bash
cp local-bin/omarchy-menu ~/.local/bin/omarchy-menu
cp local-bin/pivpn-connect.sh ~/.local/bin/pivpn-connect.sh
cp local-bin/pivpn-disconnect.sh ~/.local/bin/pivpn-disconnect.sh
cp local-bin/pivpn-watchdog.sh ~/.local/bin/pivpn-watchdog.sh
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

## 5. Root Crontab (PiVPN Watchdog)

```bash
sudo crontab -e
```

Add the line from `crontab/root-crontab.example`:

```
* * * * * /home/YOUR_USERNAME/.local/bin/pivpn-watchdog.sh
```

Replace `YOUR_USERNAME` with your actual username.

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
| PiVPN watchdog | `~/.local/bin/pivpn-watchdog.sh` |
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
| OpenVPN config | `/etc/openvpn/client/pivpn.conf` |
| OpenVPN password | `/etc/openvpn/client/pivpn.askpass` |
| Root crontab | `sudo crontab -e` |
