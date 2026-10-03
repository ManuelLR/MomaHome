# shellcheck shell=bash
# Sourced by backup.sh, prune.sh and notify-failure.sh.

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1

if [ ! -f .env ]; then
    echo "Missing $PWD/.env (copy .env.example)" >&2
    exit 1
fi
set -a
# shellcheck source=.env.example
. ./.env
set +a

# Marker lines the logwatch service keys on (logwatch/restic-o2).
# Usage: track_run backup|prune
track_run() {
    run_kind="$1"
    run_start=$(date +%s)
    trap finished EXIT
    echo "restic-o2: $run_kind started"
}

finished() {
    local rc=$? status=OK
    [ "$rc" -eq 0 ] || status="FAILED($rc)"
    echo "restic-o2: $run_kind finished status=$status duration=$(( $(date +%s) - run_start ))s"
}
