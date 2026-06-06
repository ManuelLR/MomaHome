# samba

Crude **LAN-only** network drive to quickly drop files (e.g. phone photos) for
a *temporary* backup. SMB is chosen over WebDAV/Syncthing because it is the
fastest protocol on a local network and feels like a real disk.

Uses [`crazymax/samba`](https://github.com/crazy-max/docker-samba) (actively
maintained, lightweight). It is **not** exposed through Traefik nor to the
internet: the port is bound to the IP you set in `SAMBA_BIND_IP`. To use it
from outside home, connect through WireGuard first.

## Setup

1. Set the bind address in `.env` (gitignored). Use your LAN IP:

   ```
   SAMBA_BIND_IP=192.168.x.x
   ```

2. Create your credentials/shares config from the template (also gitignored, so
   your password is never committed):

   ```
   cp config.example.yml config.yml
   # then edit config.yml and set your own password
   ```

3. The data lives on the host at `/data/samba-backup`. Create it if needed:

   ```
   sudo mkdir -p /data/samba-backup && sudo chown 1000:1000 /data/samba-backup
   ```

4. Start it:

   ```
   docker compose up -d
   ```

## Connecting from your devices

The share name is **`backup`** and requires the user/password from `config.yml`.
Replace `<ip>` with your `SAMBA_BIND_IP`.

- **iOS**: Files app → top-right menu → *Connect to Server* → `smb://<ip>`.
  It mounts as a drive. To upload photos: Photos → select → Share → *Save to
  Files* → pick the share. Originals are uploaded as-is (HEIC stays HEIC, full
  quality and metadata).
- **Android**: a file explorer with SMB support — e.g. **Amaze** (SMB / CIFS
  connection), CX File Explorer or Solid Explorer → host `<ip>`, share `backup`.
- **Windows**: `\\<ip>\backup`
- **macOS / Linux**: `smb://<ip>/backup`

You can create subfolders inside the share and choose the destination folder
freely from any of these clients.

## Notes

- Meant to be temporary: a single writable share, no history and no versioning
  (that's what `syncthing` is for).
- Files are stored as-is (no transcoding) and written as `1000:1000` to match
  the rest of the stack.
