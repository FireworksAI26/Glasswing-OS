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
- noVNC + websockify on a single exposed HTTP port: `8080`
- Landing page at `/` with an **Open Desktop** link to `/vnc.html`
- Docker health check for `http://localhost:8080/`
- Desktop services run as the non-root `glasswing` user

## Build

```bash
docker build -t glasswing:latest .
```

## Run locally

```bash
docker run --rm -p 8080:8080 -e VNC_PASSWORD='choose-a-strong-password' glasswing:latest
```

Then open:

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

## Runpod deployment

1. Create a new Runpod pod from this repository or from an image you built and pushed to a registry.
2. Expose container port `8080` as an HTTP service.
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

5. Start the pod and open the HTTP endpoint Runpod gives you.

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
- Only port `8080` is exposed.
- Plasma, Xvfb, x11vnc, and noVNC run as the non-root `glasswing` user under Supervisor.
- Put the service behind HTTPS when using it over the public internet. Runpod's HTTP proxy can provide the external TLS endpoint depending on your deployment mode.

## Customizing the Glasswing desktop

The Plasma defaults are seeded in the image under `/home/glasswing/.config/`, especially:

- `plasma-org.kde.plasma.desktop-appletsrc` for panel layout and pinned launchers
- `kdeglobals` for theme and general KDE defaults
- `kcmfonts` for font and scaling preferences
- `kwinrc` for window manager defaults

Rebuild the image after changing these files or the Dockerfile.
