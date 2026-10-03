#!/bin/bash
# Mails the tail of a failed unit's journal. Called by restic-o2-notify@.service,
# which the backup and prune units name in OnFailure=.

set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/lib.sh"

unit="$1"

{
    echo "To: ${MAIL_TO:?Define MAIL_TO in .env}"
    echo "Subject: [$(hostname)] $unit failed"
    echo
    systemctl status --no-pager "$unit" || true
    echo
    journalctl --no-pager -u "$unit" -n 80
} | msmtp "$MAIL_TO"
