#!/bin/bash
# Nightly off-site backup to O2 Cloud (restic over rclone).
# Runs on the host as root, from restic-o2-backup.service. Runs `restic backup`
# in the container over the read-only sources set in .env (BACKUP_SRC_*).
#
# Its output goes to the journal; the logwatch service in logwatch/ summarises
# the "restic-o2:" marker lines and restic's own summary into the daily report.

set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/lib.sh"

if [ ! -f excludes.txt ]; then
    echo "Missing $PWD/excludes.txt (copy excludes.example.txt)" >&2
    exit 1
fi

track_run backup

# TODO: dump every PostgreSQL server before the backup (home_automation,
# reading and immich), e.g. per compose project:
#   docker compose -f <project>/docker-compose.yml \
#       exec -T <service> sh -c 'pg_dumpall -U "${POSTGRES_USER:-postgres}"' \
#       | gzip > <dump dir>/<project>.sql.gz.tmp && mv …
# into a directory under one of the BACKUP_SRC_* paths. Until then their data directories are
# copied hot, which a running server does not guarantee to be restorable.

# This directory's secrets/ (the repository key is useless inside the
# repository it unlocks). Same path inside the container, so it matches.
docker compose run --rm restic backup \
    --retry-lock 2h \
    --tag auto \
    --exclude-caches \
    --exclude-file /etc/restic/excludes.txt \
    --exclude "$PWD/secrets" \
    "${BACKUP_SRC_DATA:?}" \
    "${BACKUP_SRC_HOME:?}" \
    "${BACKUP_SRC_DOCKER_VOLUMES:?}"
