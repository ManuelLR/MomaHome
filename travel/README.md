# travel

Self-hosted [TREK](https://github.com/mauriceboe/TREK) — a collaborative travel
planner (SQLite, single container). Runs from the published image, pinned to a
version so Renovate tracks new releases. Access is restricted to the home LAN.

## Setup

1. Create the host data directories:

   ```bash
   sudo mkdir -p /data/travel/data /data/travel/uploads
   ```

2. Copy the env template and fill it in:

   ```bash
   cp .env.example .env
   ```

   - Set `TRAVEL_EXTERNAL_DOMAIN` and `EXTERNAL_WILDCARD_DOMAIN`.
   - Generate `ENCRYPTION_KEY` with `openssl rand -hex 32` (set it once, keep it safe).
   - Set `ADMIN_EMAIL` / `ADMIN_PASSWORD` for the first admin account.

3. Start it:

   ```bash
   docker compose up -d
   ```

## Notes

- **LAN-only.** A Traefik `ipAllowList` middleware limits access to the home
  subnet (`192.168.200.0/24`). Reach it from outside via WireGuard, or widen
  `sourcerange` in `docker-compose.yml`.
- **Users.** Login is by email + password. The first admin comes from
  `ADMIN_EMAIL` / `ADMIN_PASSWORD` (first boot only); create the rest from the
  app. Open self-signup is toggled in **Admin > Settings**, not via env.
- **Encryption key.** `ENCRYPTION_KEY` encrypts stored secrets at rest. If lost,
  those secrets are unrecoverable. It lives only in `.env` (gitignored).
- **Updating.** The image tag is pinned; Renovate opens PRs for new versions.
  Apply with `docker compose up -d`.
- **Data ownership.** The container adjusts permissions on start (`cap_add:
  CHOWN`). If it fails to write, `chown` `/data/travel` to the container's uid.
