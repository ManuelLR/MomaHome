# immich

Self-hosted photo & video management ([Immich](https://immich.app)). Replaces the
mobile-photo backup use case with a proper library (timeline, albums, faces,
smart search) while keeping every original file on the LVM RAID1 pool.

**LAN-only**, exactly like `travel`: routed through Traefik with TLS, but
restricted to the home network (`192.168.200.0/24`) by an `ipallowlist`
middleware. From outside home, connect through **WireGuard** first — including
the mobile app's automatic backup.

## Architecture (4 containers)

| Service | Image | Role |
|---|---|---|
| `immich-server` | `immich-server` | API + web + jobs. The only service exposed via Traefik (port 2283). |
| `immich-machine-learning` | `immich-machine-learning` | CLIP smart search + facial recognition. Runs on **CPU**. |
| `redis` | `valkey/valkey` | Job queue (Redis-compatible). |
| `database` | `immich-app/postgres` | **Postgres 18 + VectorChord** (vector search). Not a plain postgres. |

Only `immich-server` joins the `reverse-proxy` network; everything else stays on
the private `internal` network.

### Postgres / VectorChord

Immich needs a Postgres image with the VectorChord extension (it dropped
pgvecto.rs in 3.0). We pin **`18-vectorchord1.1.1-pgvector0.8.5`**: PG18,
VectorChord 1.1.1 and pgvector 0.8.5 all sit inside Immich's supported ranges
(`PG >=14 <20`, `VectorChord >=0.3 <2.0`, `pgvector >=0.7 <0.9`). Choosing the
newest supported PG major avoids a future major-version DB migration. The plain
`common_db` from `reading/` cannot be reused — it lacks the vector extensions.

## Setup

1. Create the data folders on the host (LVM RAID1 pool). Do **not** chown the
   postgres dir — the container initializes it itself:

   ```bash
   sudo mkdir -p /data/immich/library /data/immich/model-cache /data/immich/postgres
   sudo chown -R 1000:1000 /data/immich/library /data/immich/model-cache
   ```

2. Create your `.env` from the template (gitignored, so secrets never commit):

   ```bash
   cp .env.example .env
   # set IMMICH_EXTERNAL_DOMAIN and a DB_PASSWORD (openssl rand -hex 24)
   ```

3. Make sure the shared reverse-proxy network exists (created by `reverse-proxy/`):

   ```bash
   docker network create reverse-proxy   # only if it doesn't already exist
   ```

4. Start it:

   ```bash
   docker compose up -d
   ```

   The `database` container initializes the Postgres cluster with VectorChord on
   the first boot; it may take a while and restart a couple of times before
   `immich-server` becomes reachable.

## First run

- Open `https://<IMMICH_EXTERNAL_DOMAIN>` from the LAN (or via WireGuard). **The
  first account you register in the setup wizard becomes the admin.** Create the
  other users from Administration → Users.
- **Storage labels (multi-user):** the storage template is enabled and organizes
  files as `library/<label>/{{y}}/{{y}}-{{MM}}/{{filename}}`. Assign a **Storage
  Label** to each user (Administration → Users) — e.g. `manolo`, `pareja` —
  **before they upload photos**. Without a label a user's files fall back to
  their UUID; changing a label later makes Immich *move* all their files.
- Point the Immich mobile app at the same URL for automatic backup.

## Declarative config

`immich-config.json` is mounted read-only and referenced by `IMMICH_CONFIG_FILE`.
It version-controls: VAAPI H.264 transcoding, the storage template, and reduced
job concurrency (this is a 2-core box). **Settings present in that file are
read-only in the admin UI.** It is a partial config — everything else uses
Immich defaults. To change something, edit the JSON and `docker compose up -d`.
Tip: Administration → Settings has a "copy current config" button to grab the
full JSON if you need more keys.

## Hardware transcoding (VAAPI)

`/dev/dri` is mapped into `immich-server` for hardware **video** transcoding on
the AMD Raven Ridge iGPU: it decodes H.264/HEVC and encodes H.264 (the transcode
target). Originals are always kept untouched; the H.264 copy is only generated
for clients that can't play the original (e.g. iPhone HEVC in a browser).
`group_add: 113` matches woody's `render` group. If transcoding fails with a
permission error, check `getent group render` on the host and update that GID.
Machine learning stays on CPU (gfx902 isn't supported by ROCm).

## Backup

Immich runs an **automatic database backup by default** (daily 02:00, keeps 14),
written to `library/backups` → `/data/immich/library/backups`. It contains
**only the database** (metadata/albums/faces), not the photos. Backing up
`/data/immich/library` therefore captures both the originals and the DB dumps in
one go. **Never** back up `/data/immich/postgres` hot — use those dumps to
restore. RAID1 is redundancy, not a backup.

## Updates

Renovate tracks `immich-server` + `immich-machine-learning` together (shared
`immich-app/immich` release). Immich can ship **breaking changes between
releases** — merge those PRs by hand after reading the release notes, never
auto-merge. When Immich bumps the bundled Postgres/VectorChord in a release,
update the `database` image accordingly.
