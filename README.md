# Raspberry Pi Zero 2 W Lite Rice Runbook

> Target: Raspberry Pi Zero 2 W running Raspberry Pi OS Lite / Debian 13 "trixie" on arm64.
> Last checked: 2026-05-02
> Goal: a lightweight X11/Openbox desktop with BunsenLabs-style configs, tint2, jgmenu, nitrogen, and MX Linux Conky themes.

This document is meant to be both a rebuild recipe and a repo map for the versioned configs. Commands assume you are logged in on the Pi as your normal user.

```bash
ssh <user>@<pi-host-or-ip>
```

## Repository Layout

```text
dotfiles/
  .xinitrc
  .config/
    conky/
    fontconfig/
    gtk-3.0/
    jgmenu/
    nitrogen/
    openbox/
    terminator/
    tint2/
themes/
  conky/
    MX-CowonTangram-SysInfo/
```

Apply the checked-in dotfiles after cloning this repo on the Pi:

```bash
cd ~/raspberry_pi_zero_2w
mkdir -p ~/backup-config
cp -a ~/.config ~/backup-config/config-backup-$(date +%F-%H%M%S) 2>/dev/null || true
cp -a dotfiles/. ~/
mkdir -p ~/.conky
cp -a themes/conky/. ~/.conky/
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
  terminator \
  lxappearance \
  pcmanfm \
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
- `terminator`, `geany`, and `pcmanfm` are friendly lightweight GUI defaults.

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
# Restore wallpaper chosen in nitrogen.
nitrogen --restore &

# Lightweight panel/taskbar.
tint2 &

# Desktop system monitor.
conky &

# jgmenu is opened on right-click, not started here.
EOF
```

Reload Openbox after edits:

```bash
openbox --reconfigure
```

If Openbox is not currently running, the reconfigure command will fail harmlessly; it only applies inside an active Openbox X session.

## 7. jgmenu Right-Click Menu

Current working behavior:

- Right-click on the desktop launches `jgmenu_run`.
- `jgmenu_run` should be called with no arguments.
- Pointer placement is controlled by `~/.config/jgmenu/jgmenurc`.

Create/update jgmenu config:

```bash
mkdir -p ~/.config/jgmenu

cat > ~/.config/jgmenu/jgmenurc <<'EOF'
position_mode = pointer
stay_alive = 1
csv_cmd = apps
EOF
```

Patch every Openbox right-click desktop binding to run `jgmenu_run`:

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
        command.text = "jgmenu_run"

tree.write(path, encoding="UTF-8", xml_declaration=True)
PY

openbox --reconfigure
```

Why no `--at-pointer`?

`--at-pointer` is a `jgmenu` option, not a `jgmenu_run` option. Using `jgmenu_run --at-pointer` fails with:

```text
fatal: '--at-pointer' is not a jgmenu_run command
```

Troubleshooting:

```bash
jgmenu_run
jgmenu_run --help
killall jgmenu || true
rm -f ~/.jgmenu-lockfile
```

## 8. tint2 Panel

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

Run a specific tint2 config:

```bash
killall tint2 || true
tint2 -c ~/.config/tint2/lithium.tint2rc &
```

Make that the default by editing `~/.config/openbox/autostart`:

```bash
tint2 -c ~/.config/tint2/lithium.tint2rc &
```

## 9. Wallpaper With nitrogen

Create a wallpaper folder:

```bash
mkdir -p ~/wallpapers
```

Open the wallpaper picker:

```bash
nitrogen ~/wallpapers
```

Choose a wallpaper and save it. Openbox autostart restores it with:

```bash
nitrogen --restore &
```

## 10. Conky Basics

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

## 11. Conky Manager2 And MX Theme Data

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

## 12. Appearance Tools

GTK theme and icon theme:

```bash
lxappearance
```

Openbox theme:

```bash
obconf
```

Terminator preferences:

```bash
terminator
```

Fonts worth keeping installed:

```bash
sudo apt install -y fonts-dejavu fonts-noto fonts-font-awesome
```

## 13. Performance Notes For Pi Zero 2 W

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

List running services before disabling anything:

```bash
systemctl list-units --type=service --state=running
```

Do not disable networking, SSH, dbus, or login services unless you have a recovery path.

## 14. Maintenance Commands

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

## 15. Quick Rebuild Checklist

1. Install Raspberry Pi OS Lite / Debian trixie arm64.
2. Enable SSH and log in as your normal user.
3. Run console font setup.
4. Install base packages.
5. Back up `~/.config`.
6. Clone and copy BunsenLabs `carbon` configs.
7. Create `~/.xinitrc`.
8. Configure Openbox autostart.
9. Configure jgmenu right-click.
10. Pick tint2 theme.
11. Set wallpaper with nitrogen.
12. Build/install `conky-manager2`.
13. Build/install `mx-conky-data`.
14. Launch `startx`.
15. Tune Conky and panel theme.

## 16. Troubleshooting

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
tint2 &
```

Restart Conky:

```bash
killall conky || true
conky &
```

Reset jgmenu:

```bash
killall jgmenu || true
rm -f ~/.jgmenu-lockfile
jgmenu_run
```

Check X startup errors after `startx`:

```bash
less ~/.local/share/xorg/Xorg.0.log
less ~/.xsession-errors
```

## 17. Progress Log

| Date | Item | Status | Notes |
| --- | --- | --- | --- |
| 2026-05-02 | Base Openbox desktop | Working | Xorg, xinit, Openbox, tint2, nitrogen, jgmenu, conky-all |
| 2026-05-02 | BunsenLabs configs | Working | `carbon` branch copied into `~/.config` |
| 2026-05-02 | `startx` boot file | Working | `~/.xinitrc` contains `exec openbox-session` |
| 2026-05-02 | jgmenu right-click | Working | Use `jgmenu_run` without `--at-pointer` |
| 2026-05-02 | MX Conky theme data | Installed | `mx-conky-data`, `mx-conky-data-bin`, `mx-conky-data-themes` 20251102 |
| 2026-05-02 | Conky Manager2 | Installed | Built from `~/conky-manager2`; binary at `/usr/bin/conky-manager2` |
| 2026-05-02 | MX Conky Qt manager | Skipped | Build was too swap-heavy for Pi Zero 2 W; use `conky-manager2` |
