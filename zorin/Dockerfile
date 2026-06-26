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

# --- Firefox: skip first-run welcome / Terms-of-Use, no nagging -------------
# Enterprise policy (onboarding/messaging) + AutoConfig (locks the prefs that
# gate the "Welcome to Firefox / agree to Terms of Use" modal) so a fresh
# profile lands straight on the page with no overlay.
RUN set -e \
    && FFDIR="$(dirname "$(readlink -f "$(command -v firefox)")")" \
    && install -d /etc/firefox/policies "$FFDIR/defaults/pref" \
    && printf '%s\n' \
        '{' \
        '  "policies": {' \
        '    "OverrideFirstRunPage": "",' \
        '    "OverridePostUpdatePage": "",' \
        '    "DisableProfileImport": true,' \
        '    "DontCheckDefaultBrowser": true,' \
        '    "DisableAppUpdate": true,' \
        '    "UserMessaging": {' \
        '      "WhatsNew": false,' \
        '      "ExtensionRecommendations": false,' \
        '      "FeatureRecommendations": false,' \
        '      "SkipOnboarding": true,' \
        '      "MoreFromMozilla": false' \
        '    }' \
        '  }' \
        '}' \
        > /etc/firefox/policies/policies.json \
    && printf '%s\n' \
        'pref("general.config.filename", "firefox.cfg");' \
        'pref("general.config.obscure_value", 0);' \
        'pref("general.config.sandbox_enabled", false);' \
        > "$FFDIR/defaults/pref/autoconfig.js" \
    && printf '%s\n' \
        '// Zorin headless Firefox config (first line is ignored by Firefox)' \
        '// Wrap every pref so a single type mismatch never aborts the cfg' \
        '// (a thrown error makes Firefox pop the "AutoConfig failed" alert).' \
        'function P(k, v) { try { defaultPref(k, v); } catch (e) {} }' \
        'P("datareporting.policy.dataSubmissionPolicyBypassNotification", true);' \
        'P("datareporting.policy.dataSubmissionEnabled", false);' \
        'P("browser.aboutwelcome.enabled", false);' \
        'P("trailhead.firstrun.didSeeAboutWelcome", true);' \
        'P("termsofuse.acceptedVersion", 999);' \
        'P("termsofuse.acceptedDate", "1");' \
        'P("termsofuse.bypassNotification", true);' \
        'P("browser.shell.checkDefaultBrowser", false);' \
        'P("browser.startup.homepage_override.mstone", "ignore");' \
        'P("startup.homepage_welcome_url", "");' \
        'P("startup.homepage_welcome_url.additional", "");' \
        'P("browser.startup.firstrunSkipsHomepage", true);' \
        > "$FFDIR/firefox.cfg"

# --- Zorin OS look: themes, icons, wallpapers, appearance app (best-effort) -
# Failures here must NOT break the build: worst case we ship plain GNOME.
RUN set +e; \
    add-apt-repository -y ppa:zorinos/stable; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        zorin-desktop-themes zorin-icon-themes zorin-os-wallpapers zorin-appearance; \
    echo "===== /usr/share/themes ====="; ls -1 /usr/share/themes 2>/dev/null; \
    echo "===== /usr/share/icons ====="; ls -1 /usr/share/icons 2>/dev/null; \
    echo "===== backgrounds ====="; find /usr/share/backgrounds -maxdepth 3 -type f 2>/dev/null | head -60; \
    rm -rf /var/lib/apt/lists/*; \
    true

# --- Always-visible dock: dash-to-dock -------------------------------------
# The Ubuntu/Zorin repos have NO installable dash-to-panel/dash-to-dock package
# (apt candidate = none), so we vendor the official prebuilt extension release.
# v105 ships precompiled schemas and supports GNOME Shell 45-50 (this image=46),
# so there is no version-validation mismatch. This RUN is NOT best-effort: a
# broken download should fail the build rather than ship a dock-less image.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates unzip; \
    D2D="/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"; \
    mkdir -p "$D2D"; \
    curl -fL --retry 3 -o /tmp/d2d.zip \
        "https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v105/dash-to-dock@micxgx.gmail.com.zip"; \
    unzip -o /tmp/d2d.zip -d "$D2D"; \
    glib-compile-schemas "$D2D/schemas" 2>/dev/null || true; \
    test -f "$D2D/metadata.json"; \
    rm -f /tmp/d2d.zip; \
    rm -rf /var/lib/apt/lists/*

# --- Make the dock load + stay visible via COMPILED gschema DEFAULTS --------
# Runtime gsettings/dconf writes from the autostart applier are timing- and
# dconf-socket-fragile. Baking these as the *default* values means gnome-shell
# enables dash-to-dock at session startup and the dock renders fixed/visible
# with zero runtime dependency. We install the extension's own schema into the
# global schema dir so the override below can compile against it.
RUN set -eux; \
    D2D="/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com"; \
    cp "$D2D/schemas/org.gnome.shell.extensions.dash-to-dock.gschema.xml" \
       /usr/share/glib-2.0/schemas/; \
    printf '%s\n' \
        '[org.gnome.shell]' \
        "enabled-extensions=['dash-to-dock@micxgx.gmail.com']" \
        "favorite-apps=['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']" \
        'disable-user-extensions=false' \
        'disable-extension-version-validation=true' \
        '' \
        '[org.gnome.shell.extensions.dash-to-dock]' \
        'dock-fixed=true' \
        'intellihide=false' \
        'autohide=false' \
        "dock-position='BOTTOM'" \
        'show-show-apps-button=true' \
        'extend-height=false' \
        > /usr/share/glib-2.0/schemas/zz-zorin-dock.gschema.override; \
    glib-compile-schemas /usr/share/glib-2.0/schemas/

# --- User, novnc web assets -------------------------------------------------
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && useradd --create-home --shell /bin/bash --uid 1000 zorin \
    && usermod -aG audio,video,ssl-cert zorin \
    && install -d -o zorin -g zorin -m 0700 /tmp/runtime-zorin \
    && install -d -o zorin -g zorin -m 0755 /opt/zorin /opt/zorin/www \
    && cp -a /usr/share/novnc/. /opt/zorin/www/

# --- Custom GNOME session: only org.gnome.Shell is *required* ---------------
# In a headless container there is no logind (org.freedesktop.login1), so the
# default session's required component org.gnome.SettingsDaemon.Power (gsd-power)
# exits 1 and "respawns too quickly", which makes gnome-session abort the whole
# session and show the "Oh no! Something has gone wrong." fail-whale -- even
# though gnome-shell itself starts fine. We define a session where the only
# required component is the Shell, so logind-dependent gsd-* helpers failing is
# non-fatal and the desktop renders.
RUN install -d -m 0755 /usr/share/gnome-session/sessions \
    && printf '%s\n' \
        '[GNOME Session]' \
        'Name=Zorin Session' \
        'RequiredComponents=org.gnome.Shell;' \
        > /usr/share/gnome-session/sessions/zorin.session

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
        'echo "[diag] user=$(id -un) uid=$(id -u)" | tee -a /tmp/gnome-session.log' \
        'ls -la /run/systemd 2>&1 | sed "s/^/[diag] run-systemd: /" | tee -a /tmp/gnome-session.log' \
        'if [ -e /run/systemd/seats ]; then echo "[diag] /run/systemd/seats EXISTS -> gnome-shell WILL use systemd login path" | tee -a /tmp/gnome-session.log; else echo "[diag] /run/systemd/seats MISSING -> gnome-shell will use dummy login (good)" | tee -a /tmp/gnome-session.log; fi' \
        'dbus-launch --exit-with-session gnome-session --session=zorin 2>&1 | tee -a /tmp/gnome-session.log' \
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
        'gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true' \
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

# --- Pin Firefox to an always-visible dock/taskbar -------------------------
# dash-to-dock gives a permanent dock; favorite-apps pins Firefox to it.
# Appended to the theme applier so it runs inside the live GNOME session.
RUN printf '%s\n' \
        '' \
        '# pin apps + ensure an always-visible dock (dash-to-dock)' \
        'FAV='\''["firefox.desktop", "org.gnome.Nautilus.desktop", "org.gnome.Terminal.desktop"]'\''' \
        'gsettings set org.gnome.shell favorite-apps "$FAV" 2>/dev/null || true' \
        'DTP="dash-to-dock@micxgx.gmail.com"' \
        '# disable version validation + seed enabled-extensions so the shell loads it.' \
        'gsettings set org.gnome.shell disable-extension-version-validation true 2>/dev/null || true' \
        'gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true' \
        'CUR=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null)' \
        'case "$CUR" in *"$DTP"*) : ;; *) gsettings set org.gnome.shell enabled-extensions "['\''$DTP'\'']" 2>/dev/null || true ;; esac' \
        'gnome-extensions enable "$DTP" 2>/dev/null || true' \
        '# force the dock to stay fixed/visible (no autohide) and dock at bottom' \
        'dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed true 2>/dev/null || true' \
        'dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide false 2>/dev/null || true' \
        'dconf write /org/gnome/shell/extensions/dash-to-dock/autohide false 2>/dev/null || true' \
        'dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'\''BOTTOM'\''" 2>/dev/null || true' \
        'dconf write /org/gnome/shell/extensions/dash-to-dock/show-show-apps-button true 2>/dev/null || true' \
        >> /usr/local/bin/zorin-apply-theme.sh

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
