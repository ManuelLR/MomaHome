# immich

Self-hosted photo & video management ([Immich](https://immich.app)): timeline,
albums, faces and smart search, with the originals on the LVM RAID1 pool.
LAN-only behind Traefik — from outside use WireGuard, including the mobile app's
automatic backup. Optional GPU machine learning on another host: see `remote-ml/`.

## Setup

```bash
sudo mkdir -p /data/immich/library /data/immich/model-cache /data/immich/postgres
sudo chown -R 1000:1000 /data/immich/library /data/immich/model-cache  # not postgres
cp .env.example .env    # set the domain and DB_PASSWORD (openssl rand -hex 24)
docker compose up -d
```

The database builds its cluster on first boot and may restart a couple of times
before `immich-server` answers. The first account registered becomes the admin.

## Notes

- **Give every user a Storage Label before they upload.** Without one their files
  fall back to their UUID, and setting it later makes Immich move every file.
- **`database` is not a plain postgres image.** Immich needs VectorChord since
  3.0, so the tag is pinned to a supported combination — `reading/`'s `common_db`
  cannot be reused.
- **`immich-config.json`** is a partial, version-controlled config. The keys it
  defines become read-only in the admin UI.
- **Back up `/data/immich/library`**: it holds the originals *and* the daily
  database dumps Immich writes to `library/backups`. Never copy
  `/data/immich/postgres` hot. RAID1 is redundancy, not a backup.
- **Merge Immich updates by hand** — releases can ship breaking changes.
  Renovate opens one grouped PR covering the server and both machine-learning
  images; a major release gets its own PR, so patches for the current major keep
  flowing while it waits.
- **Postgres and Valkey digests are pinned, not tracked.** Copy them from the
  [Immich release compose](https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml)
  when a release changes them.
