FROM ubuntu:24.04

# Zorin OS 18 is Ubuntu 24.04 (noble) + a customised GNOME Shell 46.
# This image recreates that experience headlessly and streams it over
# noVNC (web) and RDP, matching the Glasswing-OS architecture.

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    WIDTH=1600 \
    HEIGHT=1000 \
    DEPTH=24 \
    HOME=/home/zorin \
    XDG_RUNTIME_DIR=/tmp/runtime-zorin \
    NOVNC_HOME=/opt/zorin/www \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Core GNOME desktop + remote-access stack -------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg software-properties-common locales \
        dbus dbus-x11 supervisor sudo xauth xfonts-base x11-utils python3 \
        tigervnc-standalone-server tigervnc-common xrdp \
        websockify novnc \
        libgl1 libgl1-mesa-dri libglx-mesa0 mesa-utils \
        libegl1 libgles2 libglu1-mesa \
        gnome-session gnome-shell gnome-shell-extensions \
        gnome-shell-extension-manager \
        gnome-control-center gnome-terminal nautilus gnome-tweaks \
        gnome-menus gnome-keyring \
        dconf-cli dconf-gsettings-backend \
        fonts-noto fonts-noto-color-emoji fonts-croscore fontconfig \
    && locale-gen C.UTF-8 \
    && dbus-uuidgen --ensure \
    && rm -rf /var/lib/apt/lists/*

# --- Firefox from Mozilla's apt repo (snap-free) ----------------------------
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/packages.mozilla.org.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list \
    && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox \
    && rm -rf /var/lib/apt/lists/*

# --- Zorin OS look: themes, icons, wallpapers, appearance app (best-effort) -
# Failures here must NOT break the build: worst case we ship plain GNOME.
RUN set +e; \
    add-apt-repository -y ppa:zorinos/stable; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        zorin-desktop-themes zorin-icon-themes zorin-os-wallpapers zorin-appearance; \
    apt-get install -y --no-install-recommends gnome-shell-extension-dashtopanel; \
    echo "===== /usr/share/themes ====="; ls -1 /usr/share/themes 2>/dev/null; \
    echo "===== /usr/share/icons ====="; ls -1 /usr/share/icons 2>/dev/null; \
    echo "===== backgrounds ====="; find /usr/share/backgrounds -maxdepth 3 -type f 2>/dev/null | head -60; \
    rm -rf /var/lib/apt/lists/*; \
    true

# --- User, novnc web assets -------------------------------------------------
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && useradd --create-home --shell /bin/bash --uid 1000 zorin \
    && usermod -aG audio,video,ssl-cert zorin \
    && install -d -o zorin -g zorin -m 0700 /tmp/runtime-zorin \
    && install -d -o zorin -g zorin -m 0755 /opt/zorin /opt/zorin/www \
    && cp -a /usr/share/novnc/. /opt/zorin/www/

# --- Session wrapper + theme applier + autostart + xsession -----------------
RUN printf '%s\n' \
        '#!/usr/bin/env bash' \
        'export XDG_CURRENT_DESKTOP=GNOME' \
        'export XDG_SESSION_TYPE=x11' \
        'export GDK_BACKEND=x11' \
        'export LIBGL_ALWAYS_SOFTWARE=1' \
        'export GALLIUM_DRIVER=llvmpipe' \
        'export NO_AT_BRIDGE=1' \
        'export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe' \
        'export MESA_GL_VERSION_OVERRIDE=3.3' \
        'export CLUTTER_BACKEND=x11' \
        'export GSK_RENDERER=cairo' \
        'unset WAYLAND_DISPLAY' \
        'echo "[zorin-session] launching gnome-session at $(date)" | tee /tmp/gnome-session.log' \
        'dbus-launch --exit-with-session gnome-session --session=gnome 2>&1 | tee -a /tmp/gnome-session.log' \
        > /usr/local/bin/zorin-session.sh \
    && printf '%s\n' \
        '#!/usr/bin/env bash' \
        '# Apply Zorin theming inside the running GNOME session (best-effort).' \
        'for i in $(seq 1 30); do gsettings get org.gnome.desktop.interface gtk-theme >/dev/null 2>&1 && break; sleep 1; done' \
        'THEME=$(ls -1 /usr/share/themes 2>/dev/null | grep -iE "^Zorin" | grep -i light | head -1)' \
        '[ -z "$THEME" ] && THEME=$(ls -1 /usr/share/themes 2>/dev/null | grep -iE "^Zorin" | head -1)' \
        'ICON=$(ls -1 /usr/share/icons 2>/dev/null | grep -iE "^Zorin" | head -1)' \
        'WALL=$(find /usr/share/backgrounds -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jxl" \) 2>/dev/null | grep -i zorin | head -1)' \
        '[ -z "$WALL" ] && WALL=$(find /usr/share/backgrounds/zorin -type f 2>/dev/null | head -1)' \
        '[ -n "$THEME" ] && gsettings set org.gnome.desktop.interface gtk-theme "$THEME"' \
        '[ -n "$THEME" ] && gsettings set org.gnome.desktop.wm.preferences theme "$THEME"' \
        '[ -n "$ICON" ]  && gsettings set org.gnome.desktop.interface icon-theme "$ICON"' \
        '[ -n "$WALL" ]  && gsettings set org.gnome.desktop.background picture-uri "file://$WALL"' \
        '[ -n "$WALL" ]  && gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL"' \
        'gsettings set org.gnome.desktop.interface color-scheme "default" 2>/dev/null || true' \
        'gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true' \
        'true' \
        > /usr/local/bin/zorin-apply-theme.sh \
    && chmod +x /usr/local/bin/zorin-session.sh /usr/local/bin/zorin-apply-theme.sh \
    && install -d -m 0755 /etc/xdg/autostart \
    && printf '%s\n' \
        '[Desktop Entry]' \
        'Type=Application' \
        'Name=Zorin Theme' \
        'Exec=/usr/local/bin/zorin-apply-theme.sh' \
        'X-GNOME-Autostart-enabled=true' \
        'NoDisplay=true' \
        > /etc/xdg/autostart/zorin-theme.desktop \
    && printf '%s\n' '#!/usr/bin/env bash' 'exec /usr/local/bin/zorin-session.sh' > /home/zorin/.xsession \
    && chmod +x /home/zorin/.xsession \
    && chown zorin:zorin /home/zorin/.xsession

COPY index.html /opt/zorin/www/index.html
COPY supervisord.conf /etc/supervisor/conf.d/zorin.conf
COPY xrdp.ini /etc/xrdp/xrdp.ini
COPY vncpasswd.py /usr/local/bin/vncpasswd.py
COPY start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/vncpasswd.py \
    && chown -R zorin:zorin /home/zorin /opt/zorin

EXPOSE 8080 3389

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
  CMD curl -fsS http://localhost:8080/ >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start.sh"]
