# Zorin OS 18 — containerised desktop (RDP + noVNC)

Ubuntu 24.04 (the Zorin OS 18 base) + a Zorin-themed GNOME Shell desktop,
streamed over **noVNC** (HTTP `8080`) and **RDP** (TCP `3389`). Built for use
as a RunPod template. Same architecture as `glasswing-os`.

## Image
`docker.io/alexandermum/zorin-os-18:latest`

## Required env
- `VNC_PASSWORD` — **required**; also becomes the `zorin` Linux user's password
  (used for both RDP and the noVNC web login). Container refuses to start without it.

## Optional env
- `WIDTH` (default 1600), `HEIGHT` (default 1000), `DEPTH` (default 24)

## Ports
- `8080` — noVNC web desktop
- `3389` — RDP (username `zorin`, password = `VNC_PASSWORD`, session **Xorg**)

## RunPod
- Container image: `alexandermum/zorin-os-18:latest`
- Expose HTTP `8080` and TCP `3389`
- Env `VNC_PASSWORD=<your password>`
- Leave the start command blank (ENTRYPOINT runs `start.sh`)
- After a rebuild, **terminate + recreate** the pod so it pulls the fresh `latest`.
