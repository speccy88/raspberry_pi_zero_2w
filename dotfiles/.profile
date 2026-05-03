# ~/.profile: start the Tangram Openbox session on the main console only.

if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

if [ -z "${DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ] && command -v startx >/dev/null 2>&1; then
  exec startx
fi
