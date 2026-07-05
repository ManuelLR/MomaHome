# travel

Travel-related self-hosted services. Currently:

- **trek** — [TREK](https://github.com/mauriceboe/TREK), a collaborative travel
  planner (SQLite, single container).

Services share one `docker-compose.yml`; add more travel apps as sibling
services. Each service namespaces its env vars (`TREK_*`, ...) and its data
under `/data/travel/<service>/`. Access is restricted to the home LAN.

## Setup

1. Create the host data directories:

   ```bash
   sudo mkdir -p /data/travel/trek/data /data/travel/trek/uploads
   ```

2. Copy the env template and fill it in:

   ```bash
   cp .env.example .env
   ```

   - Set `TREK_EXTERNAL_DOMAIN` and `EXTERNAL_WILDCARD_DOMAIN`.
   - Generate `TREK_ENCRYPTION_KEY` with `openssl rand -hex 32` (set once, keep it safe).
   - Set `TREK_ADMIN_EMAIL` / `TREK_ADMIN_PASSWORD` for the first admin account.

3. Start it:

   ```bash
   docker compose up -d
   ```

## Notes

- **LAN-only.** A Traefik `ipAllowList` middleware limits access to the home
  subnet (`192.168.200.0/24`). Reach it from outside via WireGuard, or widen
  `sourcerange` in `docker-compose.yml`.
- **Users.** Login is by email + password. The first admin comes from
  `TREK_ADMIN_EMAIL` / `TREK_ADMIN_PASSWORD` (first boot only); create the rest
  from the app. Open self-signup is toggled in **Admin > Settings**, not via env.
- **Encryption key.** `TREK_ENCRYPTION_KEY` encrypts stored secrets at rest. If
  lost, those secrets are unrecoverable. It lives only in `.env` (gitignored).
- **Updating.** Image tags are pinned; Renovate opens PRs for new versions.
  Apply with `docker compose up -d`.
- **Data ownership.** The container adjusts permissions on start (`cap_add:
  CHOWN`). If it fails to write, `chown` `/data/travel/trek` to its uid.
