#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/speccy88/raspberry_pi_zero_2w.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/raspberry_pi_zero_2w}"

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
  terminator \
  lxappearance \
  pcmanfm \
  rofi \
  dillo \
  mpv \
  playerctl \
  slock \
  scrot \
  htop \
  curl \
  wget \
  unzip \
  fonts-dejavu \
  fonts-noto \
  fonts-font-awesome \
  zram-tools

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
mkdir -p "$HOME/.conky"
cp -a themes/conky/. "$HOME/.conky/"
mkdir -p "$HOME/wallpapers" "$HOME/Pictures/Screenshots" "$HOME/.local/bin"

cat > "$HOME/.local/bin/tangram-rofi-find" <<'EOS'
#!/usr/bin/env sh
find "$HOME" -maxdepth 4 -type f 2>/dev/null | sed "s#^$HOME/##"
EOS
chmod +x "$HOME/.local/bin/tangram-rofi-find"

if [ ! -f "$HOME/.xinitrc" ]; then
  printf '%s\n' 'exec openbox-session' > "$HOME/.xinitrc"
fi

sudo tee /etc/sysctl.d/99-pizero2w-rice.conf >/dev/null <<'EOS'
vm.swappiness=10
vm.vfs_cache_pressure=50
EOS
sudo sysctl --system >/dev/null || true

if [ -f /etc/default/zramswap ]; then
  sudo sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
  sudo systemctl enable --now zramswap.service >/dev/null 2>&1 || true
fi

if pgrep -x openbox >/dev/null 2>&1; then
  openbox --reconfigure || true
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
