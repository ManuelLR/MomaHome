# pets

Pet-related self-hosted services. Currently:

- **einvault** — [EinVault](https://github.com/davefatkin/EinVault), health and
  care tracker for pets (SQLite, single container): daily logs (walks with
  duration, pee/poop, meals), vet visits, vaccines, medications with doses,
  weight, documents, journal with photos, reminders and a calendar feed.

Services share one `docker-compose.yml`; add more pet apps as sibling services.
Each service namespaces its env vars (`EINVAULT_*`, ...) and its data under
`/data/pets/<service>/`. Access is restricted to the home LAN.

## Setup

1. Create the host data directory (the container runs as uid 1000 with a
   read-only root, so it cannot fix permissions itself):

   ```bash
   sudo mkdir -p /data/pets/einvault && sudo chown 1000:1000 /data/pets/einvault
   ```

2. Copy the env template and fill it in:

   ```bash
   cp .env.example .env
   ```

   - Set `EINVAULT_EXTERNAL_DOMAIN` and `EXTERNAL_WILDCARD_DOMAIN`.
   - Optional: `EINVAULT_IMMICH_URL` / `EINVAULT_IMMICH_API_KEY` and
     `EINVAULT_NTFY_URL` / `EINVAULT_NTFY_TOKEN`.

3. Start it:

   ```bash
   docker compose up -d
   ```

4. Open `https://<EINVAULT_EXTERNAL_DOMAIN>`: the first visit redirects to
   `/setup` to create the admin account (one time only). Then create the other
   user (member) and the dog.

## Daily use

- Add it to the phone home screen and create **quick logs** for the usual
  actions (walk, pee, poop, meal) to log them in one tap.
- Meals (07:30 / 19:30), deworming and vaccines as **reminders** (recurring),
  with ntfy or email notifications per user (Settings → Notifications).

## Notes

- **LAN-only.** A Traefik `ipAllowList` middleware limits access to the home
  subnet (`192.168.200.0/24`). Reach it from outside via WireGuard, or widen
  `sourcerange` in `docker-compose.yml`.
- **Home Assistant.** Not integrated on purpose for now. Ready when needed:
  - Read: its calendar feed (Settings → Calendar, a personal ICS URL) works with
    the *Remote Calendar* integration (vet visits, reminders).
  - Write: a Bearer-token API (create a write-only token in the app), e.g.
    `POST /api/logs` with `type` (`walk`, `meal`, `bathroom`…), `durationMinutes`,
    `subtypes` (`pee` / `poop`) and `loggedAt` (past events). Docs at `/api/docs`.
  - Planned once the dog wears a tracker: log walks automatically from its
    presence.
- **Backups.** Everything is in `/data/pets/einvault` (`einvault.db` and
  uploads). Stop the container before copying it so SQLite is not mid-write.
- **Updating.** Image tags are pinned; Renovate opens PRs for new versions.
  Apply with `docker compose up -d`.
