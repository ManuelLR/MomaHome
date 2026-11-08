# CrowdSec

Runs in the reverse-proxy stack and protects everything on Traefik's
`websecure` entrypoint:

- Bans IPs that scan, crawl, probe known CVEs or brute-force, plus the
  community blocklist. It gets Traefik's access log from Docker's syslog
  logging driver; `docker compose logs traefik` still works.
- AppSec (WAF): blocks requests matching known exploits (virtual patching) or
  generic attack patterns, even if the service is not patched yet.

LAN and WireGuard clients skip every check. Private addresses are never banned.

## What leaves the server

Set explicitly in `config.yaml.local` and `console.yaml` (mounted read-only),
so a change of upstream defaults does not change it:

- Sent: for each ban from a hub scenario, the scenario, timestamps, machine id,
  the attacker IP (with its AS and country) and the decision. Also, periodically,
  the CrowdSec and bouncer versions and names.
- Not sent: alert context (host, URL, user agent), custom/tainted scenarios,
  manual decisions, usage metrics. The instance is not enrolled in the console.
- `DISABLE_ONLINE_API=true` would stop all of it, losing the community blocklist.

## Data kept

Log lines are parsed in memory and discarded, except the ones that triggered an
alert, which are kept with it. Alerts and decisions are
stored, in the SQLite database under `CROWDSEC_DATA_DIR`, pruned after 60 days
or 50000 alerts (`db_config.flush`).

## Setup

1. Fill the CrowdSec variables in `reverse-proxy/.env` (see `.env.example`).
2. Put the webhook id of `HA_CROWDSEC_WEBHOOK_URL` in Home Assistant's
   `secrets.yaml` as `crowdsec_webhook_id`.
3. `docker compose up -d` in `reverse-proxy/`.

If the bouncer key changes later: `docker compose exec crowdsec cscli bouncers delete traefik`
and restart crowdsec so it registers the new one.

## Checks

```bash
docker compose exec crowdsec cscli bouncers list        # traefik, recent last pull
docker compose exec crowdsec cscli metrics              # access log lines read and parsed
docker compose exec crowdsec cscli metrics show appsec  # requests seen by the WAF
docker compose exec crowdsec cscli decisions list
docker compose exec crowdsec cscli alerts list
docker compose exec crowdsec cscli decisions delete --ip <ip>
```

From outside (mobile data, not WireGuard), `https://<host>/.env` is blocked by
the `vpatch-env-access` rule. lan-only routers also answer 403, so confirm it
in `cscli alerts list`.
