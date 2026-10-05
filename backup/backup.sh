#!/bin/bash
# Nightly off-site backup to O2 Cloud: restic in Docker, run by cron as root
# (install.sh writes the cron entry). Reads it top to bottom:
#
#   1. Sundays only: apply the retention and verify part of the data.
#   2. Back up the BACKUP_SRC_* paths from .env.
#
# Each run writes one log file to LOG_DIR. A failure mails MAIL_TO with the end
# of that log. A few summary lines also go to syslog (tag restic-o2), which is
# what the logwatch report shows.

set -uo pipefail

cd "$(dirname "$(readlink -f "$0")")" || exit 1
set -a
# shellcheck source=.env.example
. ./.env || exit 1
set +a

# send_mail SUBJECT, body on stdin.
send_mail() {
    { echo "To: $MAIL_TO"; echo "Subject: [restic-o2] $1 on $(hostname)"; echo; cat; } |
        msmtp "$MAIL_TO"
}

# One run at a time: cron starts a new run every night and the first full
# upload takes days. The kernel drops the lock when the holder exits, even if
# it is killed, so it cannot go stale. A run that hangs keeps it, though, and
# every later night would skip silently: past STUCK_AFTER_HOURS, mail instead.
# Opened with >> so a skipped run leaves the mtime alone: it marks when the
# holder started.
lock=/run/lock/restic-o2.lock
exec 9>>"$lock"
if ! flock -n 9; then
    hours=$(( ($(date +%s) - $(stat -c %Y "$lock")) / 3600 ))
    logger -t restic-o2 "skipped: previous run still going (${hours} h)"
    if [ "$hours" -ge "${STUCK_AFTER_HOURS:-96}" ]; then
        echo "The previous run started ${hours} h ago and still holds $lock." |
            send_mail "backup STUCK for ${hours} h"
    fi
    exit 0
fi
touch "$lock"

mkdir -p "$LOG_DIR"
log="$LOG_DIR/$(date +%F_%H%M).log"
exec >"$log" 2>&1
find "$LOG_DIR" -name '*.log' -mtime +90 -delete

summary() {
    echo "== $*"
    logger -t restic-o2 "$*"
}

fail() {
    summary "FAILED at $1 (log: $log)"
    { echo "Log: $log"; echo; tail -n 60 "$log"; } | send_mail "backup FAILED at $1"
    exit 1
}

restic() {
    docker compose run --rm -T restic "$@"
}

start=$(date +%s)
summary "started"

# Docker creates a missing bind-mount source as an empty directory, so a typo
# or an unmounted disk would otherwise back up nothing and still report OK.
for src in "$BACKUP_SRC_DATA" "$BACKUP_SRC_HOME" "$BACKUP_SRC_DOCKER_VOLUMES"; do
    [ -n "$(ls -A "$src" 2>/dev/null)" ] || fail "source check: $src missing or empty"
done

# TODO: dump every PostgreSQL server (home_automation, reading and immich) into
# a directory under a BACKUP_SRC_* path before backing up. Until then their data
# directories are copied hot, which a running server does not guarantee to be
# restorable.

# Retention runs before the backup, never after it: O2 lists new uploads a few
# seconds late, and a prune must not miss tonight's index.
if [ "$(date +%u)" = 7 ]; then
    restic forget --prune --retry-lock 2h \
        --keep-daily "$KEEP_DAILY" \
        --keep-weekly "$KEEP_WEEKLY" \
        --keep-monthly "$KEEP_MONTHLY" \
        --keep-yearly "$KEEP_YEARLY" \
        --max-unused "$PRUNE_MAX_UNUSED" || fail "forget/prune"

    # TODO: empty O2's trash (`rclone cleanup o2:`). Pruned packs stay there and
    # count against the quota, but it is also the safety net if a prune ever
    # deletes a pack it should not have. By hand for now.

    # A different 1/52 of the data each week: everything once a year.
    week=$((10#$(date +%V)))
    restic check --retry-lock 2h \
        --read-data-subset "$(( (week - 1) % 52 + 1 ))/52" || fail "check"
fi

# Exit code 3 (snapshot saved, some file unreadable) also counts as a failure.
restic backup --retry-lock 2h --tag auto \
    --exclude-caches \
    --exclude-file /etc/restic/excludes.txt \
    --exclude "$SECRETS_DIR" \
    "$BACKUP_SRC_DATA" "$BACKUP_SRC_HOME" "$BACKUP_SRC_DOCKER_VOLUMES" || fail "backup"

grep -E '^(Added to the repository|snapshot \S+ saved)' "$log" | while read -r line; do
    summary "$line"
done
summary "OK in $(( ($(date +%s) - start) / 60 )) min"
