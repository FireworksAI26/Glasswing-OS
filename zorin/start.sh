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
# TigerVNC-compatible password file (DES VNC auth)
printf '%s\n' "$VNC_PASSWORD" | vncpasswd -f > /home/zorin/.vnc/passwd
chown zorin:zorin /home/zorin/.vnc/passwd
chmod 0600 /home/zorin/.vnc/passwd
printf 'zorin:%s\n' "$VNC_PASSWORD" | chpasswd

# system dbus (GNOME wants one); ignore if already up
dbus-uuidgen --ensure >/dev/null 2>&1 || true

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/zorin.conf
