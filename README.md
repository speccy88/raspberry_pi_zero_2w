# Raspberry Pi Zero 2 W Lite Rice Runbook

> Target: Raspberry Pi Zero 2 W running Raspberry Pi OS Lite / Debian 13 "trixie" on arm64.
> Last checked: 2026-05-03
> Goal: a lightweight X11/Openbox desktop with a Cowon Tangram-style palette across Openbox, GTK apps, tint2, jgmenu, rofi, Dillo, mpv, Geany, PCManFM, LXTerminal, PicoClaw, Nerd Fonts, and Conky.

This document is meant to be both a rebuild recipe and a repo map for the versioned configs. Commands assume you are logged in on the Pi as your normal user.

```bash
ssh <user>@<pi-host-or-ip>
```

## Repository Layout

```text
dotfiles/
  .xinitrc
  Pictures/wallpapers/
  .config/
    conky/
    fontconfig/
    gtk-3.0/
    jgmenu/
    libfm/
    lxterminal/
    mpv/
    nitrogen/
    openbox/
    pcmanfm/
    rofi/
    tint2/
  .dillo/
  .themes/Tangram/
themes/
  conky/
    MX-CowonTangram-SysInfo/
system/
  etc/X11/xorg.conf.d/
install.sh
```

Fast install from a clean Raspberry Pi OS Lite / Debian Lite image:

```bash
sudo apt update
sudo apt install -y git ca-certificates
git clone https://github.com/speccy88/raspberry_pi_zero_2w.git ~/raspberry_pi_zero_2w
cd ~/raspberry_pi_zero_2w
./install.sh
```

Apply only the checked-in dotfiles after cloning this repo on an already configured Pi:

```bash
cd ~/raspberry_pi_zero_2w
mkdir -p ~/backup-config
cp -a ~/.config ~/backup-config/config-backup-$(date +%F-%H%M%S) 2>/dev/null || true
cp -a dotfiles/. ~/
mkdir -p ~/.conky
cp -a themes/conky/. ~/.conky/
sudo install -D -m 0644 \
  system/etc/X11/xorg.conf.d/20-vc4-noaccel.conf \
  /etc/X11/xorg.conf.d/20-vc4-noaccel.conf
```

The custom Conky theme can then be launched with:

```bash
cd ~/.conky/MX-CowonTangram-SysInfo
conky -c ./MX-CowonTangram-SysInfo &
```

## 0. Current System Snapshot

As of 2026-05-02:

```text
Hostname: set locally with hostnamectl
OS: Debian GNU/Linux 13 (trixie)
Kernel: 6.12.75+rpt-rpi-v8
Arch: arm64 / aarch64
RAM: 416 MiB usable
Root disk: /dev/mmcblk0p2, 229G total, about 214G free
Shell: /bin/bash
```

Useful check commands:

```bash
hostnamectl
uname -a
. /etc/os-release && echo "$PRETTY_NAME"
dpkg --print-architecture
free -h
df -h /
```

## 1. Console Font

For a readable text console on a small display, use UTF-8, Guess optimal, Terminus, 12x24:

```bash
sudo dpkg-reconfigure console-setup
```

Pick:

```text
Encoding: UTF-8
Character set: Guess optimal character set
Font: Terminus
Font size: 12x24
```

Apply immediately if needed:

```bash
sudo setupcon
```

## 2. Base Packages

Update package metadata first:

```bash
sudo apt update
```

Install the lightweight desktop stack and daily tools:

```bash
sudo apt install -y \
  git \
  xorg \
  xinit \
  openbox \
  obconf \
  jgmenu \
  tint2 \
  conky-all \
  nitrogen \
  feh \
  geany \
  lxterminal \
  lxappearance \
  pcmanfm \
  rofi \
  dillo \
  mpv \
  playerctl \
  slock \
  scrot \
  ncdu \
  xdotool \
  xclip \
  xsel \
  unclutter \
  fonts-jetbrains-mono \
  fonts-firacode \
  fonts-dejavu \
  fonts-noto \
  fonts-font-awesome \
  neovim \
  fish \
  htop \
  curl \
  wget \
  unzip
```

Notes:

- `openbox` is the window manager.
- `tint2` is the panel/taskbar.
- `jgmenu` is the right-click app menu.
- `nitrogen` restores wallpaper.
- `conky-all` is the Conky runtime used by MX Conky themes.
- `rofi` is the keyboard launcher.
- `dillo` is the lightweight web browser.
- `mpv` is the lightweight media player.
- `lxterminal`, `geany`, and `pcmanfm` are lightweight GUI defaults.
- JetBrainsMono Nerd Font is installed per-user by `install.sh` for readable text and icon glyphs.

Install PicoClaw from the Sipeed arm64 release package:

```bash
curl -fL --retry 3 -o /tmp/picoclaw_aarch64.deb \
  https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_aarch64.deb
sudo apt install -y /tmp/picoclaw_aarch64.deb
rm -f /tmp/picoclaw_aarch64.deb
```

`install.sh` runs this step automatically when `picoclaw` or `picoclaw-launcher` is missing.

## 3. Backup Existing Desktop Config

Before replacing config, keep a timestamped backup:

```bash
mkdir -p ~/backup-config
cp -a ~/.config ~/backup-config/config-backup-$(date +%F-%H%M%S)
```

## 4. BunsenLabs Openbox Configs

The current rice uses BunsenLabs `carbon` configs as the starting point.

```bash
cd ~

if [ ! -d ~/bunsen-configs ]; then
  git clone --depth=1 --branch carbon https://github.com/BunsenLabs/bunsen-configs.git
fi

mkdir -p ~/.config
cp -a ~/bunsen-configs/skel/.config/. ~/.config/
```

To refresh the source later:

```bash
cd ~/bunsen-configs
git pull --ff-only
```

Do not blindly re-copy over `~/.config` after you customize things. Back up first and compare files.

## 5. X Startup

Create `~/.xinitrc` so `startx` starts Openbox:

```bash
echo "exec openbox-session" > ~/.xinitrc
```

Start the graphical session manually:

```bash
startx
```

Current file:

```bash
cat ~/.xinitrc
```

Expected:

```text
exec openbox-session
```

## 6. Openbox Autostart

Openbox startup file:

```text
~/.config/openbox/autostart
```

Recommended safe autostart for the Pi Zero 2 W:

```bash
mkdir -p ~/.config/openbox

cat > ~/.config/openbox/autostart <<'EOF'
nitrogen --restore &

tint2 -c ~/.config/tint2/tangram.tint2rc &

sleep 2
conky -c ~/.conky/MX-CowonTangram-SysInfo/MX-CowonTangram-SysInfo &
EOF
```

Reload Openbox after edits:

```bash
openbox --reconfigure
```

If Openbox is not currently running, the reconfigure command will fail harmlessly; it only applies inside an active Openbox X session.

## 7. jgmenu Right-Click Menu

Current working behavior:

- Right-click on the desktop launches `~/.local/bin/tangram-menu`.
- `tangram-menu` calls `jgmenu --at-pointer --csv-file ~/.config/jgmenu/prepend.csv`, so the menu is short-lived and does not leave a resident `jgmenu` daemon in RAM.
- Pointer placement is controlled by `~/.config/jgmenu/jgmenurc`.
- Menu content is self-contained in `~/.config/jgmenu/prepend.csv`; it does not depend on BunsenLabs `bl-*` helper scripts.
- Power menu commands use `systemctl reboot` and `systemctl poweroff`, which work from the active local desktop session through logind/polkit without adding passwordless sudo rules.

Create/update jgmenu config:

```bash
mkdir -p ~/.config/jgmenu

cp -a ~/raspberry_pi_zero_2w/dotfiles/.config/jgmenu ~/.config/
```

Patch the Openbox desktop/root right-click bindings to run the Tangram menu wrapper:

```bash
mkdir -p ~/.config/openbox

if [ ! -f ~/.config/openbox/rc.xml ]; then
  cp /etc/xdg/openbox/rc.xml ~/.config/openbox/rc.xml
fi

cp ~/.config/openbox/rc.xml ~/.config/openbox/rc.xml.bak.$(date +%F-%H%M%S)

python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET

path = Path.home() / ".config/openbox/rc.xml"
tree = ET.parse(path)
root = tree.getroot()

for mousebind in root.findall(".//mousebind"):
    if mousebind.get("button") == "Right" and mousebind.get("action") == "Press":
        for child in list(mousebind):
            mousebind.remove(child)
        action = ET.SubElement(mousebind, "action", {"name": "Execute"})
        command = ET.SubElement(action, "command")
        command.text = "sh -c '$HOME/.local/bin/tangram-menu >/tmp/jgmenu-right-click.log 2>&1 &'"

tree.write(path, encoding="UTF-8", xml_declaration=True)
PY

openbox --reconfigure
```

Troubleshooting:

```bash
~/.local/bin/tangram-menu
jgmenu --help
killall jgmenu || true
rm -f ~/.jgmenu-lockfile
cat /tmp/jgmenu-right-click.log
```

## 8. Tangram Theme Coverage

The Tangram palette used across the desktop is:

```text
background: #111318
panel:      #151922
magenta:    #DB0085
cyan:       #54D8FC
green:      #A0F000
yellow:     #FFFF00
white:      #FFFFFF
muted:      #CCCCCC
```

Versioned theme/config files:

```text
~/.themes/Tangram/openbox-3/themerc
~/.themes/Tangram/gtk-3.0/gtk.css
~/.themes/Tangram/gtk-2.0/gtkrc
~/.gtkrc-2.0
~/.config/gtk-3.0/settings.ini
~/.config/tint2/tangram.tint2rc
~/.config/jgmenu/jgmenurc
~/.config/jgmenu/prepend.csv
~/.config/rofi/config.rasi
~/.config/lxterminal/LXTerminal/lxterminal.conf
~/.config/systemd/user/picoclaw-launcher.service
~/.config/geany/geany.conf
~/.config/geany/colorschemes/tangram.conf
~/.config/libfm/libfm.conf
~/.config/pcmanfm/default/pcmanfm.conf
~/.dillo/dillorc
~/.dillo/style.css
~/.config/mpv/mpv.conf
```

Apply/reload:

```bash
cp -a ~/raspberry_pi_zero_2w/dotfiles/. ~/
openbox --reconfigure
killall tint2 2>/dev/null || true
tint2 -c ~/.config/tint2/tangram.tint2rc &
```

## 9. tint2 Panel

Config directory:

```text
~/.config/tint2/
```

Current BunsenLabs tint2 configs on the Pi include:

```text
beryllium.tint2rc
boron-dark-horizontal.tint2rc
boron-dark-vertical.tint2rc
boron-light-horizontal.tint2rc
boron-light-vertical.tint2rc
crunchbang.tint2rc
fever_room.tint2rc
grey.tint2rc
helium.tint2rc
hidpi.tint2rc
lithium-light-vertical.tint2rc
lithium-light.tint2rc
lithium-vertical.tint2rc
lithium.tint2rc
yeti.tint2rc
```

Run the Tangram tint2 config:

```bash
killall tint2 || true
tint2 -c ~/.config/tint2/tangram.tint2rc &
```

Make that the default by editing `~/.config/openbox/autostart`:

```bash
tint2 -c ~/.config/tint2/tangram.tint2rc &
```

## 10. Wallpaper With nitrogen

The repo installs wallpapers into `~/Pictures/wallpapers`:

```bash
mkdir -p ~/Pictures/wallpapers
```

Open the wallpaper picker:

```bash
nitrogen ~/Pictures/wallpapers
```

The checked-in default is `cyberpunk-2077-3840x2160-13567.png`; `asus-rog-futuristic-3840x2160-11665.jpg` is included as an alternate. Choose a wallpaper and save it. Openbox autostart restores it with:

```bash
nitrogen --restore &
```

## 11. Conky Basics

Conky runtime is installed from Debian:

```bash
sudo apt install -y conky-all
conky --version
```

Start Conky:

```bash
conky &
```

Stop Conky:

```bash
killall conky
```

Conky config locations to know:

```text
~/.conky/
~/.config/conky/
/usr/share/mx-conky-data/
```

## 12. Conky Manager2 And MX Theme Data

`conky-manager2` is the installed GUI manager for Conky configs. The MX Linux `mx-conky-data` packages are also installed so their themes can be used as source material.

Launch from an active X/Openbox session:

```bash
conky-manager2 &
```

Do not test-launch it from plain SSH unless X forwarding is configured. Without a display it correctly fails with:

```text
Gtk-WARNING: cannot open display
```

### 11.1 Installed Conky Pieces

Check what is installed:

```bash
command -v conky-manager2
conky --version
dpkg -l | awk '/conky|conky-manager|mx-conky/ {print}'
```

Current expected highlights:

```text
/usr/bin/conky-manager2
conky-all 1.22.1-1
mx-conky-data 20251102
mx-conky-data-bin 20251102
mx-conky-data-themes 20251102
```

### 11.2 Install Conky Manager2 From Source

`conky-manager2` is not available in the stock Debian/Raspberry Pi OS repositories configured on this Pi. Build the maintained fork from source:

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  git \
  meson \
  valac \
  libgee-0.8-dev \
  libgtk-3-dev \
  libjson-glib-dev \
  gettext \
  libgettextpo-dev \
  p7zip-full \
  imagemagick \
  rsync

cd ~
if [ ! -d ~/conky-manager2 ]; then
  git clone https://github.com/zcot/conky-manager2.git
else
  git -C ~/conky-manager2 pull --ff-only
fi

cd ~/conky-manager2
make -j1
sudo make install
```

Notes:

- The build emits many GTK/Vala deprecation warnings on Debian 13. That is expected and does not mean the build failed.
- The source install places the binary at `/usr/bin/conky-manager2`.
- The desktop launcher is installed at `/usr/share/applications/conky-manager2.desktop`.
- Uninstall command from the same source tree:

```bash
cd ~/conky-manager2
sudo make uninstall
```

### 11.3 MX Conky Theme Data

MX Conky theme data was built from the upstream MX Linux source:

```text
~/mx-conky-data
```

Current source revisions checked on 2026-05-02:

```text
mx-conky-data 7a52395 2026-04-26 Update Debian packaging standards
```

Install build dependencies for the data package:

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  debhelper \
  devscripts \
  conky-all
```

Build and install the data package:

```bash
cd ~/mx-conky-data
git pull --ff-only
dpkg-buildpackage -us -uc -b

cd ~
sudo apt install -y ./mx-conky-data-bin_*.deb ./mx-conky-data-themes_*.deb ./mx-conky-data_*.deb
```

The data packages are `Architecture: all`, so they are suitable for this arm64 Pi.

### 11.4 Use MX Themes With Conky Manager2

List installed MX Conky files:

```bash
find /usr/share/mx-conky-data -maxdepth 3 -type f | sort | less
```

Copy a theme into your home config before editing it:

```bash
mkdir -p ~/.conky
cp -a /usr/share/mx-conky-data/* ~/.conky/
```

Then run a specific config:

```bash
conky -c ~/.conky/path/to/conky.conf &
```

Exact theme paths vary by upstream package version, so use `find` after installation. `conky-manager2` also has an import flow for theme packs; if a theme is just a directory of `.conkyrc` / `conky.conf` files, copy it under `~/.conky` and rescan from the manager.

### 11.5 Custom Hybrid Theme

Custom theme created on 2026-05-02:

```text
~/.conky/MX-CowonTangram-SysInfo/MX-CowonTangram-SysInfo
```

It combines the large Cowon Tangram clock, the information layout from `MX-MyConky/MySysInfoConky`, and Pi-friendly system commands:

```text
magenta: DB0085
cyan:    54D8FC
green:   A0F000
yellow:  FFFF00
white:   FFFFFF
muted:   CCCCCC
```

Launch manually from an active X/Openbox session:

```bash
cd ~/.conky/MX-CowonTangram-SysInfo
conky -c ./MX-CowonTangram-SysInfo &
```

If testing over SSH while X is running on `:0`:

```bash
cd ~/.conky/MX-CowonTangram-SysInfo
DISPLAY=:0 conky -c ./MX-CowonTangram-SysInfo &
```

Stop it:

```bash
pkill -f 'conky.*MX-CowonTangram-SysInfo'
```

### 11.6 What Not To Build On This Pi

The Qt6 `mx-conky` manager can be built from `~/mx-conky`, but it is heavy for the Pi Zero 2 W. A parallel build caused heavy swapping on the 416 MiB system, so the manager build was stopped intentionally. Use `conky-manager2` as the GUI manager instead.

## 13. Appearance Tools

GTK theme and icon theme:

```bash
lxappearance
```

Openbox theme:

```bash
obconf
```

Launcher:

```bash
rofi -show drun
```

Browser:

```bash
dillo
```

Media player:

```bash
mpv --player-operation-mode=pseudo-gui --idle=yes
```

Terminal:

```bash
lxterminal
```

Terminator and xterm were removed from the default setup. LXTerminal is readable, GTK-themed, and much lighter than Terminator while still being friendlier than plain xterm.

Fonts worth keeping installed:

```bash
sudo apt install -y fonts-jetbrains-mono fonts-firacode fonts-dejavu fonts-noto fonts-font-awesome
```

## 14. Performance Notes For Pi Zero 2 W

The Pi has about 416 MiB usable RAM, so keep startup sparse.

Target idle footprint:

```text
Openbox:    about 30-50 MiB
tint2:      about 5-10 MiB
jgmenu:     about 5-15 MiB, mostly on demand
nitrogen:   one-shot wallpaper restore
conky:      about 10-25 MiB depending on theme
```

Check memory:

```bash
free -h
ps -eo pid,comm,rss,%mem --sort=-rss | head -n 20
```

Optional lower swappiness:

```bash
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system
```

Raspberry Pi OS Bookworm/Trixie already provides generated zram swap on this image. Do not install `zram-tools` on top of that; it conflicts with the generated `/dev/zram0` swap and leaves `zramswap.service` failed. The installer masks `zramswap.service` and keeps the native generated zram swap instead.

The installer also writes small systemd drop-ins so shutdown/reboot does not wait too long on stale GUI session scopes:

```text
/etc/systemd/system.conf.d/99-tangram-fast-stop.conf
/etc/systemd/logind.conf.d/99-tangram-session-cleanup.conf
```

Those set a 10 second stop timeout and clean up user processes when the session ends. This is intentionally appliance-like behavior for a small Pi desktop.

The installer disables services that are not needed for a plain SSH/Openbox desktop:

```text
avahi-daemon
bluetooth / hciuart
cups / cups-browsed
NetworkManager-wait-online
serial-getty@ttyS0
cloud-init
udisks2
zramswap.service
```

It keeps SSH, NetworkManager, wpa_supplicant, dbus, systemd-logind, polkit, and time sync.

PicoClaw is installed by downloading the latest Sipeed aarch64 `.deb` package:

```text
https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_aarch64.deb
```

It then runs as a user service:

```bash
systemctl --user status picoclaw-launcher.service
```

The installer enables linger for the installing user so this user service can start at boot:

```bash
sudo loginctl enable-linger "$USER"
```

Dashboard:

```text
http://localhost:18800
```

List running services before disabling anything:

```bash
systemctl list-units --type=service --state=running
```

Do not disable networking, SSH, dbus, or login services unless you have a recovery path.

## 15. Maintenance Commands

Update Debian/Raspberry Pi packages:

```bash
sudo apt update
sudo apt full-upgrade
sudo apt autoremove
```

Check Conky and manager packages:

```bash
command -v conky-manager2
dpkg -l | awk '/mx-conky|conky-manager|conky-all/ {print}'
```

Update source clones:

```bash
cd ~/conky-manager2 && git pull --ff-only
cd ~/mx-conky-data && git pull --ff-only
```

Rebuild/reinstall Conky Manager2 after pulling:

```bash
cd ~/conky-manager2
make -j1
sudo make install
```

Rebuild MX theme data after pulling:

```bash
cd ~/mx-conky-data
dpkg-buildpackage -us -uc -b
cd ~
sudo apt install -y ./mx-conky-data-bin_*.deb ./mx-conky-data-themes_*.deb ./mx-conky-data_*.deb
```

Clean build artifacts:

```bash
cd ~/conky-manager2 && make clean
cd ~/mx-conky-data && fakeroot debian/rules clean
```

## 16. Quick Rebuild Checklist

1. Install Raspberry Pi OS Lite / Debian trixie arm64.
2. Enable SSH and log in as your normal user.
3. Run `sudo apt install -y git ca-certificates`.
4. Clone this repo.
5. Run `./install.sh`.
6. Log in on tty1. `~/.profile` starts X automatically there; SSH logins remain terminal-only.
7. Right-click the desktop for jgmenu.
8. Use `rofi -show drun` for app launching.
9. Use the Power submenu for log out, reboot, and power off.

## 17. Troubleshooting

Validate Openbox XML:

```bash
python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET
ET.parse(Path.home() / ".config/openbox/rc.xml")
print("Openbox rc.xml OK")
PY
```

Reload Openbox:

```bash
openbox --reconfigure
```

Restart panel:

```bash
killall tint2 || true
tint2 -c ~/.config/tint2/tangram.tint2rc &
```

Restart Conky:

```bash
killall conky || true
cd ~/.conky/MX-CowonTangram-SysInfo
conky -c ./MX-CowonTangram-SysInfo &
```

Reset jgmenu:

```bash
killall jgmenu || true
rm -f ~/.jgmenu-lockfile
~/.local/bin/tangram-menu
```

Check X startup errors after `startx`:

```bash
less ~/.local/share/xorg/Xorg.0.log
less ~/.xsession-errors
```

If `startx` hangs and SSH still works, check the kernel log for a Raspberry Pi VC4 DRM reset loop:

```bash
sudo dmesg -T | tail -n 80
```

Repeated `[drm] Resetting GPU.` lines mean Xorg has wedged the VC4 acceleration path. This repo installs `/etc/X11/xorg.conf.d/20-vc4-noaccel.conf`, which keeps the modesetting driver but disables Xorg acceleration and DRI:

```text
Option "AccelMethod" "none"
Option "DRI" "0"
```

If the reset loop is already active, kill the stuck Xorg process and reboot before trying `startx` again:

```bash
pkill -9 Xorg || true
sudo reboot
```

Verify Conky is not clipped at the screen edge with a screenshot:

```bash
mkdir -p ~/Pictures/Screenshots
scrot -z ~/Pictures/Screenshots/conky-check.png
```

Open the screenshot and confirm the first colored Conky pixels do not touch the top edge of the screen. The custom theme now uses a smaller Cowon clock and explicit top-right anchoring with a screen gap, which is more reliable under Openbox than asking a normal Conky window to sit at the bottom while drawing a tall clock.

## 18. Progress Log

| Date | Item | Status | Notes |
| --- | --- | --- | --- |
| 2026-05-02 | Base Openbox desktop | Working | Xorg, xinit, Openbox, tint2, nitrogen, jgmenu, conky-all |
| 2026-05-02 | BunsenLabs configs | Working | `carbon` branch copied into `~/.config` |
| 2026-05-02 | `startx` boot file | Working | `~/.xinitrc` contains `exec openbox-session` |
| 2026-05-02 | jgmenu right-click | Working | Use `~/.local/bin/tangram-menu` with `jgmenu --at-pointer` |
| 2026-05-02 | MX Conky theme data | Installed | `mx-conky-data`, `mx-conky-data-bin`, `mx-conky-data-themes` 20251102 |
| 2026-05-02 | Conky Manager2 | Installed | Built from `~/conky-manager2`; binary at `/usr/bin/conky-manager2` |
| 2026-05-02 | MX Conky Qt manager | Skipped | Build was too swap-heavy for Pi Zero 2 W; use `conky-manager2` |
| 2026-05-03 | Tangram system theme | Working | GTK, Openbox, tint2, jgmenu, rofi, Dillo, mpv, Geany, PCManFM, LXTerminal |
| 2026-05-03 | Self-contained jgmenu | Working | Removed Bunsen `bl-*` helper dependencies; power menu uses `systemctl` |
| 2026-05-03 | Clean installer | Added | `install.sh` clones/applies the repo and installs packages from a Lite base |
| 2026-05-03 | PicoClaw launcher | Working | Installer downloads Sipeed `picoclaw_aarch64.deb`; user service runs `picoclaw-launcher` on localhost port 18800 with linger enabled |
| 2026-05-03 | Service trimming | Working | Disabled Avahi, Bluetooth, CUPS, cloud-init, serial getty, wait-online, and udisks |
| 2026-05-03 | Console desktop start | Working | `~/.profile` starts `startx` only on `/dev/tty1` |
| 2026-05-03 | VC4 Xorg hang workaround | Added | Installs `20-vc4-noaccel.conf` to disable Xorg acceleration/DRI on the Pi Zero 2 W |
| 2026-05-03 | Bundled wallpapers | Added | Includes Cyberpunk 2077 and ASUS ROG wallpapers under `~/Pictures/wallpapers` |
