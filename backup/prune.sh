#!/bin/bash
# Weekly maintenance of the off-site restic repository in O2 Cloud.
# Runs on the host as root, from restic-o2-prune.service.
#
# Kept apart from backup.sh, hours away from it: O2 lists new uploads a few
# seconds late, and a prune that cannot see a just-written index would treat
# its packs as unused and delete them.

set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/lib.sh"

track_run prune

docker compose run --rm restic forget \
    --retry-lock 2h \
    --prune \
    --keep-daily "${KEEP_DAILY:-30}" \
    --keep-weekly "${KEEP_WEEKLY:-26}" \
    --keep-monthly "${KEEP_MONTHLY:-36}" \
    --keep-yearly "${KEEP_YEARLY:-unlimited}" \
    --max-unused "${PRUNE_MAX_UNUSED:-15%}"

# TODO: empty O2's trash (`rclone cleanup o2:`). Deletes there are soft: the
# packs prune removes land in the trash and keep counting against the quota.
# Not done automatically on purpose: the trash is the safety net if a prune ever
# deletes a pack it should not have (O2 lists new uploads late). Run it by hand
# when space is needed; see README.md.

# Read back a different 1/52 of the pack data each ISO week, so every byte gets
# downloaded and verified about once a year without pulling the whole
# repository weekly.
week=$((10#$(date +%V)))
subset="$(( (week - 1) % 52 + 1 ))/52"
echo "restic-o2: checking data subset $subset"

docker compose run --rm restic check \
    --retry-lock 2h \
    --read-data-subset "$subset"
