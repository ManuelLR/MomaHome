# galley

Self-hosted web app. The source is a git submodule at [`src/`](src) and the image is
**built locally** (nothing is published to a registry). It is served on a public
domain, with the admin UI and the legacy domain restricted to the home LAN.

## Setup

1. Fetch the source (submodule):

   ```bash
   git submodule update --init galley/src
   ```

2. Create the host data directory:

   ```bash
   sudo mkdir -p /data/galley && sudo chown 1000:1000 /data/galley
   ```

3. Copy the env template and set your domains (`GALLEY_EXTERNAL_DOMAIN` is the
   live one, `GALLEY_LEGACY_DOMAIN` the old one being redirected):

   ```bash
   cp .env.example .env
   ```

4. Build and start it (the first build takes a while):

   ```bash
   docker compose up -d --build
   ```

## Notes

- **Exposure.** The app is public on `GALLEY_EXTERNAL_DOMAIN`. A Traefik
  `ipAllowList` limited to the home subnet (`192.168.200.0/24`) covers the
  PocketBase admin dashboard (`/_/`) and the whole legacy domain; reach those from
  outside via WireGuard.
  The `/_/` rule hides the admin **UI**, and that is all it does — it is not real
  protection. The superuser REST endpoints under `/api` remain public, and
  PocketBase accepts collections by id as well as by name, so no path filter would
  close that off. What actually protects the data is PocketBase's own auth: keep a
  strong superuser password and scope the Home Assistant service token.
- **Domain move.** `GALLEY_LEGACY_DOMAIN` answers only on the LAN and 302s to
  `GALLEY_EXTERNAL_DOMAIN`, preserving path and query. It is meant for humans and
  bookmarks, not for the PWA: the service worker serves the shell from cache and
  the PocketBase client talks to `window.location.origin`, so an installed app on
  the old origin has to be uninstalled and reinstalled from the new one (the auth
  token lives in per-origin localStorage, so a fresh login is needed either way).
  Home Assistant's `galley_*_resource` secrets should point straight at the new
  domain rather than lean on the redirect.
  Keep the legacy domain resolving to the Traefik host from the LAN, and its
  certificate renewable, for as long as the redirect is in place.
- **Updating.** The submodule is pinned to a commit; update with
  `git submodule update --remote galley/src`, then `docker compose up -d --build`.
  Renovate does not track it.
