FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    WIDTH=1600 \
    HEIGHT=1000 \
    DEPTH=24 \
    HOME=/home/glasswing \
    XDG_RUNTIME_DIR=/tmp/runtime-glasswing \
    NOVNC_HOME=/opt/glasswing/www

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus \
        dbus-x11 \
        gnupg \
        supervisor \
        sudo \
        xauth \
        xvfb \
        x11vnc \
        xrdp \
        xorgxrdp \
        websockify \
        novnc \
        plasma-desktop \
        plasma-workspace \
        plasma-workspace-wayland \
        kde-cli-tools \
        systemsettings \
        dolphin \
        konsole \
        breeze \
        breeze-gtk-theme \
        fonts-croscore \
        fonts-noto \
        fonts-noto-color-emoji \
        fontconfig \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/packages.mozilla.org.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list \
    && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox \
    && useradd --create-home --shell /bin/bash --uid 1000 glasswing \
    && usermod -aG audio,video,ssl-cert glasswing \
    && install -d -o glasswing -g glasswing -m 0700 /tmp/runtime-glasswing \
    && install -d -o glasswing -g glasswing -m 0755 /opt/glasswing /opt/glasswing/www \
    && cp -a /usr/share/novnc/. /opt/glasswing/www/ \
    && apt-get purge -y --auto-remove gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY index.html /opt/glasswing/www/index.html
COPY supervisord.conf /etc/supervisor/conf.d/glasswing.conf
COPY start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh \
    && chown -R glasswing:glasswing /home/glasswing /opt/glasswing /tmp/runtime-glasswing \
    && install -d -o glasswing -g glasswing -m 0755 \
        /home/glasswing/.config \
        /home/glasswing/.local/share/wallpapers/glasswing \
    && printf '%s\n' '#!/usr/bin/env bash' 'exec dbus-run-session -- startplasma-x11' > /home/glasswing/.xsession \
    && chmod +x /home/glasswing/.xsession \
    && printf '%s\n' \
        '[KDE]' \
        'SingleClick=false' \
        'LookAndFeelPackage=org.kde.breeze.desktop' \
        '' \
        '[General]' \
        'ColorScheme=BreezeLight' \
        'Name=Glasswing OS' \
        > /home/glasswing/.config/kdeglobals \
    && printf '%s\n' \
        '[General]' \
        'font=Noto Sans,12,-1,5,50,0,0,0,0,0' \
        'menuFont=Noto Sans,12,-1,5,50,0,0,0,0,0' \
        'smallestReadableFont=Noto Sans,10,-1,5,50,0,0,0,0,0' \
        'toolBarFont=Noto Sans,11,-1,5,50,0,0,0,0,0' \
        '' \
        '[KScreen]' \
        'ScaleFactor=1.25' \
        'ScreenScaleFactors=1.25' \
        > /home/glasswing/.config/kcmfonts \
    && printf '%s\n' \
        '[Compositing]' \
        'Enabled=true' \
        'OpenGLIsUnsafe=false' \
        '' \
        '[Windows]' \
        'BorderlessMaximizedWindows=false' \
        'ElectricBorders=false' \
        '' \
        '[org.kde.kdecoration2]' \
        'theme=__aurorae__svg__Breeze' \
        > /home/glasswing/.config/kwinrc \
    && printf '%s\n' \
        '[Containments][1]' \
        'activityId=' \
        'formfactor=0' \
        'immutability=1' \
        'lastScreen=0' \
        'location=0' \
        'plugin=org.kde.plasma.folder' \
        'wallpaperplugin=org.kde.color' \
        '' \
        '[Containments][1][Wallpaper][org.kde.color][General]' \
        'Color=34,45,62' \
        '' \
        '[Containments][2]' \
        'activityId=' \
        'formfactor=2' \
        'immutability=1' \
        'lastScreen=0' \
        'location=4' \
        'plugin=org.kde.panel' \
        '' \
        '[Containments][2][General]' \
        'alignment=132' \
        'floating=1' \
        'length=720' \
        'maxLength=900' \
        'minLength=420' \
        'panelVisibility=0' \
        'thickness=64' \
        '' \
        '[Containments][2][Applets][3]' \
        'immutability=1' \
        'plugin=org.kde.plasma.kickoff' \
        '' \
        '[Containments][2][Applets][4]' \
        'immutability=1' \
        'plugin=org.kde.plasma.icontasks' \
        '' \
        '[Containments][2][Applets][4][Configuration][General]' \
        'launchers=applications:org.mozilla.firefox.desktop,applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop,applications:systemsettings.desktop' \
        'showOnlyCurrentDesktop=false' \
        '' \
        '[Containments][2][Applets][5]' \
        'immutability=1' \
        'plugin=org.kde.plasma.marginsseparator' \
        '' \
        '[Containments][2][Applets][6]' \
        'immutability=1' \
        'plugin=org.kde.plasma.systemtray' \
        '' \
        '[Containments][2][Applets][7]' \
        'immutability=1' \
        'plugin=org.kde.plasma.digitalclock' \
        '' \
        '[Containments][2][General]' \
        'AppletOrder=3;4;5;6;7' \
        > /home/glasswing/.config/plasma-org.kde.plasma.desktop-appletsrc \
    && chown -R glasswing:glasswing /home/glasswing

EXPOSE 8080 3389

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:8080/ >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start.sh"]
