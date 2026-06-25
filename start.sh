#!/usr/bin/env bash
set -euo pipefail

: "${WIDTH:=1600}"
: "${HEIGHT:=1000}"
: "${DEPTH:=24}"
: "${DISPLAY:=:1}"
: "${XDG_RUNTIME_DIR:=/tmp/runtime-glasswing}"

if [ -z "${VNC_PASSWORD:-}" ]; then
  echo "ERROR: VNC_PASSWORD is required. Refusing to start without VNC password auth." >&2
  echo "Example: docker run --rm -p 8080:8080 -e VNC_PASSWORD='choose-a-strong-password' glasswing:latest" >&2
  exit 64
fi

export WIDTH HEIGHT DEPTH DISPLAY XDG_RUNTIME_DIR HOME=/home/glasswing USER=glasswing

install -d -o glasswing -g glasswing -m 0700 "$XDG_RUNTIME_DIR"
install -d -o glasswing -g glasswing -m 0700 /home/glasswing/.vnc
printf '%s' "$VNC_PASSWORD" | x11vnc -storepasswd - /home/glasswing/.vnc/passwd >/dev/null
chown glasswing:glasswing /home/glasswing/.vnc/passwd
chmod 0600 /home/glasswing/.vnc/passwd
printf 'glasswing:%s\n' "$VNC_PASSWORD" | chpasswd

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/glasswing.conf
