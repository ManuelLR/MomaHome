# samba

Crude **LAN-only** network drive to quickly drop photos from a phone for a
*temporary* backup. Chosen over WebDAV/Syncthing because SMB is the fastest
protocol on a local network and feels like a real disk.

It is **not** exposed through Traefik nor to the internet: ports are bound to
the LAN IP (`192.168.200.7`). To use it from outside home, connect through
WireGuard first.

## Setup

1. Define the credentials in `.env` (gitignored):

   ```
   SAMBA_USER=moma
   SAMBA_PASSWORD=change-me
   ```

2. The data lives on the host at `/data/samba-backup`. Create it if needed:

   ```
   sudo mkdir -p /data/samba-backup && sudo chown 1000:1000 /data/samba-backup
   ```

3. Start it:

   ```
   docker compose up -d
   ```

## Connecting from your devices

The share name is **`backup`** and requires the user/password above.

- **iOS**: Files app → top-right menu → *Connect to Server* → `smb://192.168.200.7`.
  It mounts as a drive. To upload photos: Photos → select → Share → *Save to
  Files* → pick the share. For a smoother "drop and forget" flow, a photo
  backup app like PhotoSync (SMB target) selects the whole camera roll at once.
- **Android**: a file explorer with SMB support — e.g. **Amaze** (*Cloud
  connections / SMB*), CX File Explorer or Solid Explorer → host
  `192.168.200.7`, share `backup`.
- **Windows**: `\\192.168.200.7\backup`
- **macOS / Linux**: `smb://192.168.200.7/backup`

## Notes

- It's meant to be temporary: there is a single writable share, no history and
  no versioning (that's what `syncthing` is for).
- Files are written as `1000:1000` to match the rest of the stack.
