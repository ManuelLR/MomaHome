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
- **Android**:
  - *Browse / drop a few files manually*: any SMB-capable file explorer
    (Amaze, CX File Explorer, Solid Explorer) → host `<ip>`, share `backup`.
    Note these do foreground transfers, so a big upload can be interrupted if
    the screen goes off.
  - *Reliable background backup (recommended)*: a real sync app with a
    background service — **[SMBSync2](https://github.com/Sentaroh/SMBSync2)**
    (open source, SMB-native, scheduling + retries) or
    **[Round Sync](https://github.com/newhinton/Round-Sync)** (open source,
    rclone-based). Set the app's battery usage to **Unrestricted**
    (Settings → Apps → [app] → Battery), otherwise Android's Doze mode kills
    the transfer when the screen is off.
- **Windows**: `\\<ip>\backup`
- **macOS / Linux**: `smb://<ip>/backup`

You can create subfolders inside the share and choose the destination folder
freely from any of these clients.

## Notes

- Meant to be temporary: a single writable share, no history and no versioning
  (that's what `syncthing` is for).
- Files are stored as-is (no transcoding) and written as `1000:1000` to match
  the rest of the stack.
