#!/usr/bin/env bash
set -euo pipefail

: "${WIDTH:=1600}"
: "${HEIGHT:=1000}"
: "${DEPTH:=24}"
: "${DISPLAY:=:1}"
: "${XDG_RUNTIME_DIR:=/tmp/runtime-zorin}"

if [ -z "${VNC_PASSWORD:-}" ]; then
  echo "ERROR: VNC_PASSWORD is required. Refusing to start without VNC password auth." >&2
  echo "Example: docker run --rm -p 8080:8080 -e VNC_PASSWORD='choose-a-strong-password' zorin-os-18:latest" >&2
  exit 64
fi

export WIDTH HEIGHT DEPTH DISPLAY XDG_RUNTIME_DIR HOME=/home/zorin USER=zorin

install -d -o zorin -g zorin -m 0700 "$XDG_RUNTIME_DIR"
install -d -o zorin -g zorin -m 0700 /home/zorin/.vnc
# VncAuth password file (Ubuntu's TigerVNC ships no `vncpasswd` binary, so
# we generate the standard DES-obfuscated file ourselves).
python3 /usr/local/bin/vncpasswd.py "$VNC_PASSWORD" /home/zorin/.vnc/passwd
chown zorin:zorin /home/zorin/.vnc/passwd
chmod 0600 /home/zorin/.vnc/passwd
printf 'zorin:%s\n' "$VNC_PASSWORD" | chpasswd

# system dbus (GNOME wants one); ignore if already up
dbus-uuidgen --ensure >/dev/null 2>&1 || true

# --- GNOME Shell 46 logind crash workaround --------------------------------
# gnome-shell uses LoginManagerSystemd *iff* /run/systemd/seats exists
# (GLib.access('/run/systemd/seats') >= 0), then opens a proxy to
# org.freedesktop.login1 on the system bus. We run no logind, so that proxy
# is NULL and gnome-shell segfaults (signal 11), crash-looping into the
# "Oh no" failed-session screen. Removing the dir makes haveSystemd() false
# so gnome-shell falls back to its supported LoginManagerDummy.
rm -rf /run/systemd/seats /run/systemd/sessions /run/systemd/users 2>/dev/null || true

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/zorin.conf
