# Off-site backup (restic → O2 Cloud)

Encrypted, versioned, automatic copy of the home server in O2 Cloud (Spain).
It complements the existing local backup to an external disk, which it does not
replace or touch.

- **restic** does the backup: client-side encryption (file contents, names and
  tree structure), deduplication, snapshots, retention.
- **rclone** is only the transport (`restic -r rclone:o2:…`). Stock rclone has
  no O2 backend yet, so the image builds it from the unmerged
  [rclone#9536](https://github.com/rclone/rclone/pull/9536) (`funambol`
  backend), pinned to a commit in the `Dockerfile`.
- Runs as a one-shot container, started nightly by a systemd timer on the host.
  Sources are mounted read-only at their host paths, so snapshots show real
  paths.
- Everything host-specific (paths, host name, mail, repository location) lives
  in local files that git ignores; the repo only carries generic templates.

| File | What |
|---|---|
| `Dockerfile` | restic + rclone built from the PR commit |
| `docker-compose.yml` | the `restic` service: repository, secrets, cache |
| `.env.example` | template for the host settings |
| `excludes.example.txt` | template for the restic exclusions |
| `lib.sh` | loads `.env`; run markers for logwatch |
| `backup.sh` | nightly `restic backup` of the three `BACKUP_SRC_*` paths |
| `prune.sh` | weekly `forget --prune` (30 daily / 26 weekly / 36 monthly) + partial `check` |
| `notify-failure.sh` | mails the journal of a failed unit (msmtp) |
| `systemd/` | services and timers (backup 03:30 nightly, prune Sunday 15:00) |
| `logwatch/` | logwatch service that adds the runs to the daily report |
| **not in git** | `.env`, `excludes.txt`, `secrets/` (`restic-password`, `rclone.conf`) |

## Keys

The repository has two keys, both unlocking the same data:

1. **Automation key**: random, in `secrets/restic-password`, used by the timers.
2. **Recovery passphrase**: one you memorise (and keep in the password
   manager), added with `restic key add`. restic stretches it with scrypt.

Recovering after losing the server needs only the passphrase and the O2 account
login: build this image anywhere (or any restic + an rclone with the O2
backend), `rclone config` the remote, and run restic with the passphrase. No
password is ever stored in this repo.

## Running as root

The container runs as root because it has to read every file under the
sources, whatever their owner and mode. What bounds it:

- the sources are mounted **read-only**;
- no Docker socket is mounted, so it cannot reach other containers or the host;
- the only writable mounts are `secrets/` (rclone renews its session there) and
  the restic cache directory;
- it only runs while a backup or prune is running (`docker compose run --rm`).

## Setup

All commands from this directory on the server, as root.

```bash
cp .env.example .env                  # host settings, including the source paths
cp excludes.example.txt excludes.txt  # what to leave out
docker compose build restic

install -d -m 700 secrets
openssl rand -base64 48 > secrets/restic-password
chmod 600 secrets/restic-password
```

### 1. O2 remote

```bash
docker compose run --rm --entrypoint rclone restic config
#   n) New remote → name: o2 → storage: funambol
#   user: your O2 Cloud email, pass: your O2 Cloud password
```

Log in with the O2 Cloud **email and password**, not the SMS login: only the
password login keeps working unattended. The first login may ask for a
verification code.

The remote registers itself as a new device in the O2 account. Its session is
saved in `secrets/rclone.conf` and renewed on every use (~90 day rolling window),
which is why `secrets/` is mounted read-write.

**Check the session survives before going further.** Run this once a day for
two or three days; it must keep answering without asking for a new login:

```bash
docker compose run --rm --entrypoint rclone restic about o2:
```

If it ever lapses: `docker compose run --rm --entrypoint rclone restic config reconnect o2:`.

### 2. Repository and keys

```bash
docker compose run --rm restic init
docker compose run --rm restic key add      # type the memorised passphrase
docker compose run --rm restic key list     # two keys
```

### 3. Small test

```bash
docker compose run --rm restic backup --tag test /srv/data/some/dir
docker compose run --rm restic snapshots
docker compose run --rm -v /tmp/restore-test:/restore restic \
    restore latest --tag test --target /restore
diff -r /srv/data/some/dir /tmp/restore-test/srv/data/some/dir
docker compose run --rm restic forget --prune <test snapshot ID>  # drop it
```

### 4. Timers

The versioned units carry a `@BACKUP_DIR@` placeholder instead of this
directory's real path; fill it in while installing:

```bash
for f in systemd/*; do
    sed "s#@BACKUP_DIR@#$PWD#g" "$f" > "/etc/systemd/system/$(basename "$f")"
done
systemctl daemon-reload
systemctl enable --now restic-o2-backup.timer restic-o2-prune.timer
systemctl list-timers 'restic-o2-*'
```

The first full upload can take many hours. Start it by hand rather than waiting
for the timer: `systemctl start --no-block restic-o2-backup.service`, and
follow it with `journalctl -fu restic-o2-backup`. Later runs only upload
changes. There is no bandwidth limit.

A failed run mails `MAIL_TO` through `restic-o2-notify@.service`. A restic exit
code 3 (snapshot saved, but some file could not be read) also counts as a
failure, on purpose.

### 5. Logwatch

```bash
cp logwatch/restic-o2.conf /etc/logwatch/conf/services/
cp logwatch/restic-o2 /etc/logwatch/scripts/services/
logwatch --service restic-o2 --range Today --output stdout   # try it
```

The daily report then gets an "Off-site backup" section with each run's
status, duration, snapshot, what was added, what prune removed, the check
result and any errors. It reads the journal of both units directly.

## Restore

```bash
docker compose run --rm restic snapshots
docker compose run --rm restic ls latest /srv/data/apps/myapp
docker compose run --rm restic find 'some-file*'

# Restore a path from a snapshot to a scratch directory, then copy back by hand.
docker compose run --rm -v /tmp/restore:/restore restic \
    restore latest --include /srv/data/apps/myapp --target /restore
```

Browse every snapshot as a directory tree (FUSE, inside the container):

```bash
docker compose run --rm --cap-add SYS_ADMIN --device /dev/fuse \
    -v /tmp/restore:/restore --entrypoint sh restic
# then, inside:
mkdir /mnt/r && restic mount /mnt/r &
ls /mnt/r/snapshots/latest/srv/data/
cp -a /mnt/r/snapshots/latest/srv/data/… /restore/
```

## Manual commands

```bash
docker compose run --rm restic stats --mode raw-data   # space used in O2
docker compose run --rm restic check --read-data       # full verify (downloads everything)
docker compose run --rm restic unlock                  # after a crashed run left a stale lock
docker compose run --rm --entrypoint rclone restic about o2:    # quota
docker compose run --rm --entrypoint rclone restic cleanup o2:  # empty O2's trash
```

Deletes in O2 are soft: packs removed by prune go to the trash and still count
against the 5 TB quota. The trash is left alone on purpose (see TODO); empty it
by hand when the space is needed, never right after a prune.

### Viewing and freeing space

Snapshots are deduplicated: they share every chunk of data they have in common.
So deleting a snapshot only frees the data that **no other snapshot** still
references. Removing one nightly snapshot out of thirty usually frees almost
nothing.

The commands below drop the `docker compose run --rm restic` prefix:
`alias r='docker compose run --rm restic'` from this directory.

```bash
r stats latest                    # restore size: what the snapshot contains
r stats --mode raw-data           # what the whole repository really takes in O2
r diff <snapshot-a> <snapshot-b>  # files added, removed and changed between two snapshots
journalctl -u restic-o2-backup | grep 'Added to the repository'  # growth per night
```

What a delete would free, before freeing it:

```bash
r forget <snapshot-id>   # only removes the snapshot record
r prune --dry-run        # reports how much data would be deleted
r prune                  # actually deletes it
```

To purge something big from **every** snapshot (a directory that should never
have been backed up), rewrite the snapshots without it, then prune. Add the path
to `excludes.txt` first so the next backup does not bring it back:

```bash
r rewrite --exclude /srv/data/some/big/dir --forget --dry-run   # check what changes
r rewrite --exclude /srv/data/some/big/dir --forget
r prune
```

Run `prune` by hand away from the 03:30 backup, for the same reason as
`prune.sh` (O2 lists new uploads late). The freed packs go to O2's trash, so the
quota only goes down after `rclone cleanup o2:`.

## Updating rclone

`RCLONE_COMMIT` in the `Dockerfile` is pinned by hand; Renovate does not track
it. To move to a newer commit of the PR, read what changed, update the SHA,
`docker compose build restic`, and run `about o2:` before the next backup.

## TODO / pending improvements

- **Database dumps.** `pg_dumpall` of every PostgreSQL server in the repo
  (`home_automation`, `reading`, `immich`) before each backup, into a path that
  is backed up (see the TODO in `backup.sh`). Today their data directories are
  copied hot, like the local backup does, which a running PostgreSQL does not
  guarantee to be restorable. Once the dumps exist, the data directories can go
  to `excludes.txt`.
- **Emptying O2's trash.** Automate `rclone cleanup o2:` (see the TODO in
  `prune.sh`) once there is confidence that prune never removes live packs.
  Until then the trash is a safety net that costs quota.
- **Periodic restore test.** Quarterly, from another machine: build the image,
  configure the remote, open the repository with the memorised passphrase only
  and restore a sample. It is the only proof the recovery path works.
- **Official rclone backend.** When rclone ships O2 support (upstream may merge
  it as a generic `onemediahub` backend), drop the build stage, use the official
  binary and reconfigure the remote. The restic repository does not change.
