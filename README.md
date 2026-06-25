# Glasswing OS

Glasswing OS is a reproducible Dockerized Linux desktop concept for Windows and macOS switchers. It uses **Ubuntu 24.04** as the distro base and layers on a curated **KDE Plasma** experience with familiar defaults: a centered dock-style bottom panel, clean Breeze styling, readable fonts, Firefox, Dolphin, Konsole, and browser-based access through noVNC.

This repository intentionally builds a runnable root filesystem and desktop container, not an ISO image.

## What is included

- Ubuntu 24.04 base image
- KDE Plasma desktop session on a headless X server
- Centered bottom dock-style Plasma panel with pinned apps
- Breeze theme defaults, Noto/Croscore fonts, and iPhone-friendly UI scaling
- Firefox, Dolphin, Konsole, and System Settings launchers
- Xvfb on `DISPLAY=:1` with overridable `WIDTH`, `HEIGHT`, and `DEPTH`
- Mandatory password-protected x11vnc
- noVNC + websockify on HTTP port `8080`
- Optional direct RDP access on port `3389` for mobile RDP clients
- Landing page at `/` with an **Open Desktop** link to `/vnc.html`
- Docker health check for `http://localhost:8080/`
- Browser desktop services run as the non-root `glasswing` user
- RDP login uses username `glasswing` and the same password supplied in `VNC_PASSWORD`

## Build

```bash
docker build -t glasswing:latest .
```

## Run locally

```bash
docker run --rm -p 8080:8080 -p 3389:3389 -e VNC_PASSWORD='choose-a-strong-password' glasswing:latest
```

For browser/noVNC access, open:

```text
http://localhost:8080/
```

Click **Open Desktop**, or go directly to:

```text
http://localhost:8080/vnc.html
```

Enter the same password you supplied in `VNC_PASSWORD`.

## Run with Docker Compose

Edit `docker-compose.yml` and replace `change-me-now` with a strong password, then run:

```bash
docker compose up --build
```

## RDP app access from your phone

You can connect with Microsoft Remote Desktop, Jump Desktop, Remotix, or another RDP client.

Use these connection settings locally:

```text
Host: localhost or your Docker host IP
Port: 3389
Username: glasswing
Password: the value of VNC_PASSWORD
Session: Xorg, if your client asks
```

On Runpod, do **not** assume the external RDP port is `3389`. Runpod shows a Direct TCP mapping after the pod starts, for example:

```text
TCP port 203.0.113.10:13007 -> :3389
```

In your phone RDP app, enter:

```text
Host / PC name: 203.0.113.10
Port: 13007
Username: glasswing
Password: the value of VNC_PASSWORD
```

When running locally, map the RDP port:

```bash
docker run --rm -p 8080:8080 -p 3389:3389 -e VNC_PASSWORD='choose-a-strong-password' glasswing:latest
```

On Runpod, expose container TCP port `3389` in addition to HTTP port `8080` if you want native RDP app access. After the pod starts, open **Connect** and copy the **Direct TCP Ports** public IP and assigned external port for `:3389`. Keep `8080` enabled if you also want the Safari/noVNC fallback.

## Runpod deployment

1. Create a new Runpod pod from this repository or from an image you built and pushed to a registry.
2. Expose container port `8080` as an HTTP service. For RDP apps, also add container port `3389` to **Expose TCP Ports**.
3. Set an environment variable before the pod starts:

   ```text
   VNC_PASSWORD=choose-a-strong-password
   ```

4. Optionally set the remote desktop size for your device:

   ```text
   WIDTH=1600
   HEIGHT=1000
   DEPTH=24
   ```

5. Start the pod. For browser access, open the HTTP endpoint Runpod gives you. For RDP, open **Connect → Direct TCP Ports** and use the displayed public IP plus the assigned external port that maps to `:3389`.

## iPhone Safari instructions

1. On your iPhone, open Safari.
2. Go to:

   ```text
   http(s)://RUNPOD_HOST:8080/
   ```

3. Tap **Open Desktop**. You can also go directly to `/vnc.html`.
4. Enter the password from `VNC_PASSWORD`.
5. Rotate the phone to landscape for a wider desktop.
6. Use noVNC's side drawer for keyboard, scaling, clipboard, and disconnect controls.

## Security notes

- `VNC_PASSWORD` is required. The container exits if it is missing.
- Ports `8080` and `3389` are exposed for browser/noVNC and native RDP access.
- Plasma, Xvfb, x11vnc, noVNC, and xrdp are managed by Supervisor; browser desktop processes run as the non-root `glasswing` user.
- Put the service behind HTTPS when using it over the public internet. Runpod's HTTP proxy can provide the external TLS endpoint depending on your deployment mode.

## Customizing the Glasswing desktop

The Plasma defaults are seeded in the image under `/home/glasswing/.config/`, especially:

- `plasma-org.kde.plasma.desktop-appletsrc` for panel layout and pinned launchers
- `kdeglobals` for theme and general KDE defaults
- `kcmfonts` for font and scaling preferences
- `kwinrc` for window manager defaults

Rebuild the image after changing these files or the Dockerfile.
