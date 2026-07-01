# galley

Self-hosted web app. The source is a git submodule at [`src/`](src) and the image is
**built locally** (nothing is published to a registry). Access is restricted to the
home LAN.

## Setup

1. Fetch the source (submodule):

   ```bash
   git submodule update --init galley/src
   ```

2. Create the host data directory:

   ```bash
   sudo mkdir -p /data/galley && sudo chown 1000:1000 /data/galley
   ```

3. Copy the env template and set your domain:

   ```bash
   cp .env.example .env
   ```

4. Build and start it (the first build takes a while):

   ```bash
   docker compose up -d --build
   ```

## Notes

- **LAN-only.** A Traefik `ipAllowList` middleware limits access to the home subnet
  (`192.168.200.0/24`). Reach it from outside via WireGuard, or widen `sourcerange`
  in `docker-compose.yml`.
- **Updating.** The submodule is pinned to a commit; update with
  `git submodule update --remote galley/src`, then `docker compose up -d --build`.
  Renovate does not track it.
