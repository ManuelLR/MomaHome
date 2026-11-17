#!/bin/bash
# Installs or updates everything the off-site backup needs outside this
# directory. Safe to run again after every `git pull`. Run as root from here.
#
#   - checks .env and excludes.txt exist (copied from the *.example* files)
#   - creates SECRETS_DIR, the cache and the log directory
#   - builds the image
#   - writes /etc/cron.d/restic-o2 and the logwatch service
#
# The interactive steps (O2 login, restic init, recovery key) are in README.md.

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" != 0 ]; then
    echo "Run as root." >&2
    exit 1
fi

if [ ! -f .env ] || [ ! -f excludes.txt ]; then
    echo "First copy and edit the host settings, then run this again:" >&2
    echo "  cp .env.example .env; cp excludes.example.txt excludes.txt" >&2
    exit 1
fi

set -a
# shellcheck source=.env.example
. ./.env
set +a

install -d -m 700 "$SECRETS_DIR"
install -d "$CACHE_DIR" "$LOG_DIR"

docker compose build --pull restic

cat > /etc/cron.d/restic-o2 <<EOF
# Off-site backup to O2 Cloud. Managed by $PWD/install.sh.
$CRON_SCHEDULE root $PWD/backup.sh
EOF
echo "Cron: $CRON_SCHEDULE $PWD/backup.sh"

install -D -m 644 logwatch/restic-o2.conf /etc/logwatch/conf/services/restic-o2.conf
install -D -m 755 logwatch/restic-o2 /etc/logwatch/scripts/services/restic-o2
echo "Logwatch: restic-o2 service installed"

echo
[ -s "$SECRETS_DIR/restic-password" ] || echo "Pending: create $SECRETS_DIR/restic-password (README, step 2)"
[ -s "$SECRETS_DIR/rclone.conf" ] || echo "Pending: configure the O2 remote (README, step 2)"
echo "Done."
