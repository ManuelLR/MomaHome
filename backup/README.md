# Off-site backup (restic → O2 Cloud)

Encrypted, versioned, automatic copy of the home server in O2 Cloud (Spain).
It complements the local backup to an external disk, which it does not touch.

- **restic** does the backup: client-side encryption (contents, names and tree),
  deduplication, snapshots, retention.
- **rclone** is only the transport (`rclone:o2:…`). No rclone release supports
  O2 yet, so the image builds it from the unmerged
  Funambol backend (rclone pull request 9536), pinned to a commit
  that Renovate follows.
- **cron** runs `backup.sh` nightly. That one script does everything, in order,
  and writes one log file per run.

| File | What |
|---|---|
| `backup.sh` | the nightly run: Sunday retention + check, then the backup |
| `install.sh` | installs/updates the cron entry, logwatch service and image |
| `Dockerfile` | restic + rclone built from the PR commit |
| `docker-compose.yml` | the `restic` service: sources read-only, secrets, cache |
| `.env.example`, `excludes.example.txt` | templates for the host settings |
| `logwatch/` | logwatch service showing the summary lines of each run |
| **not in git** | `.env`, `excludes.txt`, `secrets/` (`restic-password`, `rclone.conf`) |

## What a run does

`backup.sh`, started by `/etc/cron.d/restic-o2`:

1. Skips if the previous run is still going (the first upload takes days). The
   lock is released by the kernel when that run ends or dies, so it cannot go
   stale; if a run hangs past `STUCK_AFTER_HOURS` (96 h), each skipped night
   mails a warning.
2. **Sundays:** `forget --prune` with the retention in `.env` (30 daily, 26
   weekly, 36 monthly, all yearly), then `check` of a different 1/52 of the data
   each week. It runs *before* the backup because O2 lists new uploads a few
   seconds late, and a prune must not miss tonight's data.
3. `restic backup` of the three `BACKUP_SRC_*` paths.

**Where to look:**

- Everything a run printed: `LOG_DIR/<date>_<time>.log`.
- On failure, `MAIL_TO` gets a mail (msmtp) with the failed step and the end of
  the log. A restic exit code 3 (snapshot saved, some file unreadable) counts as
  a failure.
- Daily logwatch report: a "restic -> O2 Cloud" section with each run's
  `started` / `snapshot … saved` / `Added to the repository` / `OK` or `FAILED`
  lines (syslog tag `restic-o2`; `journalctl -t restic-o2` shows the same).

## Keys

Two keys open the same repository:

1. **Automation key**: random, in `secrets/restic-password`, used by cron.
2. **Recovery passphrase**: one you memorise, added with `restic key add`.

Recovering after losing the server needs only the passphrase and the O2 login:
build this image anywhere, configure the remote, run restic with the
passphrase. No password is stored in this repo.

## Running as root

The container runs as root to read every file whatever its owner. The sources
are mounted read-only, there is no Docker socket, only `secrets/` and the cache
are writable, and the container only exists while a run lasts.

## Setup

On the server, from this directory, as root.

### 1. Install

```bash
cp .env.example .env                  # paths, host name, mail, retention, …
cp excludes.example.txt excludes.txt  # what to leave out
./install.sh
```

### 2. Keys and O2 remote

```bash
openssl rand -base64 48 > secrets/restic-password && chmod 600 secrets/restic-password

docker compose run --rm --entrypoint rclone restic config
#   n) New remote → name: o2 → storage: funambol
#   user: your O2 Cloud email, pass: your O2 Cloud password
```

Log in with the O2 Cloud **email and password**, not the SMS login: only the
password login keeps working unattended. The first login may ask for a
verification code. The session is saved in `secrets/rclone.conf` and renewed on
every use (~90-day rolling window), which is why `secrets/` is writable.

```bash
docker compose run --rm --entrypoint rclone restic about o2:   # must show the quota
```

If the session ever lapses: `docker compose run --rm --entrypoint rclone restic config reconnect o2:`.

### 3. Repository

```bash
docker compose run --rm restic init
docker compose run --rm restic key add      # type the memorised passphrase
docker compose run --rm restic key list     # two keys
```

### 4. First run

Start it by hand instead of waiting for cron; it takes days (~5 MiB/s upload):

```bash
nohup ./backup.sh &
tail -f "$(ls -t /var/log/restic-offsite/*.log | head -1)"   # your LOG_DIR
```

Nightly cron runs skip while it is going. Later runs only upload changes.

### Updating

After `git pull`, run `./install.sh` again: it rebuilds the image and rewrites
the cron entry and the logwatch files.

## Restore

Restore into a scratch directory on the data disk, never under `/tmp`: on
Debian trixie `/tmp` is a RAM-backed tmpfs.

```bash
alias r='docker compose run --rm restic'
r snapshots
r ls latest /srv/data/apps/myapp
r find 'some-file*'
docker compose run --rm -v /srv/data/restore-tmp:/restore restic \
    restore latest --include /srv/data/apps/myapp --target /restore
```

Browse every snapshot as a directory tree (FUSE, inside the container):

```bash
docker compose run --rm --cap-add SYS_ADMIN --device /dev/fuse \
    -v /srv/data/restore-tmp:/restore --entrypoint sh restic
mkdir /mnt/r && restic mount /mnt/r &     # then, inside
ls /mnt/r/snapshots/latest/srv/data/
```

## Space

Snapshots share every chunk they have in common, so deleting one only frees
what **no other snapshot** references.

```bash
r stats --mode raw-data           # what the repository takes in O2
r stats latest                    # what a snapshot contains (restore size)
r diff <snapshot-a> <snapshot-b>  # what changed between two snapshots
grep -h 'Added to the repository' /var/log/restic-offsite/*.log   # growth per night

r forget <snapshot-id> && r prune --dry-run    # what deleting one would free
```

To purge something big from **every** snapshot, add it to `excludes.txt`, then:

```bash
r rewrite --exclude /srv/data/some/big/dir --forget --dry-run
r rewrite --exclude /srv/data/some/big/dir --forget
r prune
```

Run `prune` by hand well away from the nightly run. Pruned data goes to O2's
trash and still counts against the quota until
`docker compose run --rm --entrypoint rclone restic cleanup o2:` (never right
after a prune).

Other: `r check --read-data` (full verify, downloads everything), `r unlock`
(stale lock after a crash).

## TODO

- **Database dumps** of every PostgreSQL server (`home_automation`, `reading`,
  `immich`) before the backup (see `backup.sh`). Today their data directories
  are copied hot, which is not guaranteed to restore.
- **Emptying O2's trash** automatically, once there is confidence that prune
  never removes live data. Until then the trash is a safety net.
- **Periodic restore test**, e.g. quarterly from another machine with only the
  memorised passphrase.
- **Official rclone backend** once released: drop the build stage, reconfigure
  the remote. The repository does not change.
