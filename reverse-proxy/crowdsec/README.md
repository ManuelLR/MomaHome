# CrowdSec

Runs in the reverse-proxy stack and protects everything on Traefik's
`websecure` entrypoint:

- Bans IPs that scan, crawl, probe known CVEs or brute-force (reads the access
  log), plus the community blocklist.
- AppSec (WAF): blocks requests matching known exploits (virtual patching) or
  generic attack patterns, even if the service is not patched yet.

LAN and WireGuard clients skip every check. Private addresses are never banned.

## What leaves the server

For each local ban, CrowdSec's Central API receives the scenario, the
timestamp, this machine's id and the attacker IP. No host names, URLs, headers
or bodies; AppSec runs locally. The instance is not enrolled in the CrowdSec
console, so alert context is never uploaded. `DISABLE_ONLINE_API=true` stops
sharing altogether, losing the community blocklist.

## Setup

1. Fill the CrowdSec and access-log variables in `reverse-proxy/.env`
   (see `.env.example`). The bouncer key reaches both containers as a Compose
   secret read from the environment, which needs a recent Docker Compose v2.
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
docker compose logs -f access-log                       # Traefik access log
```

From outside (mobile data, not WireGuard), `https://<host>/.env` is blocked by
the `vpatch-env-access` rule. lan-only routers also answer 403, so confirm it
in `cscli alerts list`.
