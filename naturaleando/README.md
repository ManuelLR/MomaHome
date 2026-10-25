# naturaleando

[Naturaleando](https://github.com/ManuelLR/Naturaleando) (branch `poc`): static
web built with Vite + TypeScript. A single `nginx-unprivileged` container serves
the already built `dist/` folder, mounted read-only from the host. Traefik
routes the domain to it.

Nothing is built on the server and **no data lives in this repo or in the
image**: the site loads `data/*.geojson` (~41 MB), generated with GDAL from
REDIAM / DERA / Catastro data. They are not in the Naturaleando repo either
(size and licensing: the Catastro licence forbids redistributing the original
data), so they are copied to the server together with the build.

## Setup

1. Create the host folder (owned by the user that will `rsync` into it):

   ```bash
   sudo mkdir -p /data/naturaleando/dist
   sudo chown "$USER": /data/naturaleando/dist
   ```

2. Copy the env template and fill it in:

   ```bash
   cp .env.example .env
   ```

   - Set `NATURALEANDO_EXTERNAL_DOMAIN` and `EXTERNAL_WILDCARD_DOMAIN`.
   - `NATURALEANDO_DIST_PATH` only if you do not use `/data/naturaleando/dist`.

3. Start it:

   ```bash
   docker compose up -d
   ```

## Deploy / update the site (from the machine that has the data)

```bash
cd Naturaleando            # branch poc, with public/data/*.geojson generated locally
npm ci && npm run build    # produces dist/ (the GeoJSON in public/data/ ends up in dist/data/)
rsync -av --delete dist/ <server>:/data/naturaleando/dist/
```

No container restart is needed: nginx reads the files from disk and
`index.html` is never cached. Check that `dist/data/*.geojson` exists before
syncing; `--delete` removes whatever is not in `dist/`.

## Notes

- **LAN-only (temporary).** Like every other router, it carries the
  `global-lan-only@file` middleware (see
  `reverse-proxy/file-dynamic-conf/lan-only.yaml`). `git grep lan-only.yaml`
  lists it with the rest. To publish it to the internet, remove that label and
  recreate the container; consider first the pending points below.
- **Caching.** `/assets/*` (hashed by Vite): 1 year, `immutable`.
  `index.html` and `/data/*` (no hash): `no-cache`, i.e. revalidate with ETag.
  gzip is enabled, including `application/geo+json`.
- **Headers.** `nosniff` and `Referrer-Policy`. No CSP yet: the site loads
  external OpenStreetMap tiles and queries Nominatim from the browser.
- **Healthcheck.** `/healthz` answers `ok` even if `dist/` is empty, so it only
  proves nginx is up, not that the site was deployed.
- **Alternative (not implemented).** A multi-stage image (`node` builds the
  repo, `nginx` serves it) with the geodata mounted separately at `/data/`.
  It would avoid the manual `rsync` of code, but needs the Naturaleando repo
  as a build context (submodule like `galley`) and a rebuild on each change.

## Pending before opening it to the internet

- Check the DERA licence/terms for republishing the derived data.
- Public OSM tiles and Nominatim have usage policies; with real traffic use
  another provider or host your own.
