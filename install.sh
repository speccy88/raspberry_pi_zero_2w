#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/speccy88/raspberry_pi_zero_2w.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/raspberry_pi_zero_2w}"
PICOCLAW_DEB_URL="${PICOCLAW_DEB_URL:-https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_aarch64.deb}"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as the normal desktop user, not root." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required on a clean Lite install." >&2
  exit 1
fi

sudo apt update
sudo apt install -y \
  git \
  ca-certificates \
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
  htop \
  ncdu \
  xdotool \
  xclip \
  xsel \
  unclutter \
  curl \
  wget \
  unzip \
  fonts-jetbrains-mono \
  fonts-firacode \
  fonts-dejavu \
  fonts-noto \
  fonts-font-awesome

if ! command -v picoclaw >/dev/null 2>&1 || ! command -v picoclaw-launcher >/dev/null 2>&1; then
  tmp_picoclaw_dir="$(mktemp -d)"
  curl -fL --retry 3 -o "$tmp_picoclaw_dir/picoclaw_aarch64.deb" "$PICOCLAW_DEB_URL"
  sudo apt install -y "$tmp_picoclaw_dir/picoclaw_aarch64.deb"
  rm -rf "$tmp_picoclaw_dir"
fi

if [ ! -d "$TARGET_DIR/.git" ]; then
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$REPO_URL" "$TARGET_DIR"
else
  git -C "$TARGET_DIR" pull --ff-only
fi

cd "$TARGET_DIR"

mkdir -p "$HOME/backup-config"
if [ -d "$HOME/.config" ]; then
  cp -a "$HOME/.config" "$HOME/backup-config/config-backup-$(date +%F-%H%M%S)"
fi

cp -a dotfiles/. "$HOME/"
chmod +x "$HOME/.local/bin/tangram-menu" 2>/dev/null || true
mkdir -p "$HOME/.conky"
cp -a themes/conky/. "$HOME/.conky/"
mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots" "$HOME/.local/bin"

if ! fc-match 'JetBrainsMono Nerd Font' | grep -qi 'JetBrainsMono'; then
  tmp_font_dir="$(mktemp -d)"
  mkdir -p "$HOME/.local/share/fonts/nerd-fonts/JetBrainsMono"
  curl -fL --retry 3 -o "$tmp_font_dir/JetBrainsMono.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -oq "$tmp_font_dir/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/nerd-fonts/JetBrainsMono"
  rm -rf "$tmp_font_dir"
  fc-cache -f "$HOME/.local/share/fonts"
fi

cat > "$HOME/.local/bin/tangram-rofi-find" <<'EOS'
#!/usr/bin/env sh
find "$HOME" -maxdepth 4 -type f 2>/dev/null | sed "s#^$HOME/##"
EOS
chmod +x "$HOME/.local/bin/tangram-rofi-find"

if [ ! -f "$HOME/.xinitrc" ]; then
  printf '%s\n' 'exec openbox-session' > "$HOME/.xinitrc"
fi

if [ -f system/etc/X11/xorg.conf.d/20-vc4-noaccel.conf ]; then
  sudo install -D -m 0644 \
    system/etc/X11/xorg.conf.d/20-vc4-noaccel.conf \
    /etc/X11/xorg.conf.d/20-vc4-noaccel.conf
fi

sudo tee /etc/sysctl.d/99-pizero2w-rice.conf >/dev/null <<'EOS'
vm.swappiness=10
vm.vfs_cache_pressure=50
EOS
sudo sysctl --system >/dev/null || true

sudo mkdir -p /etc/systemd/system.conf.d /etc/systemd/logind.conf.d
sudo tee /etc/systemd/system.conf.d/99-tangram-fast-stop.conf >/dev/null <<'EOS'
[Manager]
DefaultTimeoutStopSec=10s
EOS
sudo tee /etc/systemd/logind.conf.d/99-tangram-session-cleanup.conf >/dev/null <<'EOS'
[Login]
KillUserProcesses=yes
UserStopDelaySec=5s
EOS
sudo systemctl daemon-reexec || true

for unit in \
  avahi-daemon.service avahi-daemon.socket \
  bluetooth.service hciuart.service \
  cups.service cups.socket cups-browsed.service \
  NetworkManager-wait-online.service \
  serial-getty@ttyS0.service \
  cloud-init-local.service cloud-init-network.service cloud-config.service cloud-final.service cloud-init-main.service \
  cloud-init-hotplugd.socket cloud-init.target \
  udisks2.service \
  zramswap.service
do
  sudo systemctl disable --now "$unit" >/dev/null 2>&1 || true
done

sudo systemctl mask \
  NetworkManager-wait-online.service \
  serial-getty@ttyS0.service \
  cloud-init-main.service cloud-init-hotplugd.socket cloud-init.target \
  zramswap.service >/dev/null 2>&1 || true
sudo systemctl reset-failed zramswap.service >/dev/null 2>&1 || true
sudo loginctl enable-linger "$USER" >/dev/null 2>&1 || true

systemctl --user daemon-reload || true
systemctl --user enable --now picoclaw-launcher.service >/dev/null 2>&1 || true

if [ -n "${DISPLAY:-}" ] && pgrep -x openbox >/dev/null 2>&1; then
  timeout 5s openbox --reconfigure >/tmp/tangram-openbox-reconfigure.log 2>&1 || true
fi

if [ -n "${DISPLAY:-}" ]; then
  killall tint2 2>/dev/null || true
  tint2 -c "$HOME/.config/tint2/tangram.tint2rc" >/tmp/tangram-tint2.log 2>&1 &
  pkill -f 'conky.*MX-CowonTangram-SysInfo' 2>/dev/null || true
  (cd "$HOME/.conky/MX-CowonTangram-SysInfo" && conky -c ./MX-CowonTangram-SysInfo >/tmp/tangram-conky.log 2>&1 &)
fi

cat <<EOS
Tangram rice installed.

Start the desktop with:
  startx

Inside Openbox, right-click the desktop for jgmenu or run:
  rofi -show drun
EOS
