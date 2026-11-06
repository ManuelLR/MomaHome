# CrowdSec

Detects and blocks attacks against the services published by Traefik:

- **Behaviour**: reads Traefik's access log and bans IPs that scan, crawl,
  probe known CVEs or brute-force (base HTTP scenarios).
- **WAF (AppSec)**: Traefik sends every public request to CrowdSec before it
  reaches the service. Requests matching a known exploit (virtual patching) or
  a generic attack pattern are blocked even if the service is not patched yet.
- **Community blocklist**: IPs reported by other CrowdSec users are banned in
  advance.

```
internet ──► Traefik websecure ──► crowdsec@file middleware (plugin) ──► router ──► service
                 │ access.log (tmpfs)        │ banned list (60 s) + AppSec
                 └──────────► crowdsec ◄─────┘
                                 └──► Home Assistant webhook (bans)
```

LAN and WireGuard clients skip every check (`clientTrustedIPs`), and private
addresses are never banned (`crowdsecurity/whitelists` parser).

## What leaves the server

With signal sharing on (default), for each local ban CrowdSec's Central API
receives: the scenario name, hash and version, the timestamp, this machine's id
and the attacker IP. **No host names, URLs, headers or bodies.** AppSec runs
locally. CrowdSec also sees this server's public IP (it connects to download the
blocklist) and the list of installed scenarios.

The instance is **not** enrolled in the CrowdSec console and `share_context`
stays `false`: alert context (which could carry the targeted host) is never
uploaded. To stop sharing altogether set `DISABLE_ONLINE_API=true` in the
compose file, at the cost of losing the community blocklist.

## Behaviour when CrowdSec is down

Fail closed for the internet: AppSec is unreachable, so public requests get a
403. LAN/WireGuard keep working and Traefik starts without CrowdSec.

## First setup

```bash
# 1. Shared bouncer key (read by both containers). Before any `up`, otherwise
#    Docker creates a directory with that name.
mkdir -p crowdsec/secrets
openssl rand -hex 32 > crowdsec/secrets/bouncer_key_traefik
chmod 600 crowdsec/secrets/bouncer_key_traefik

# 2. Home Assistant webhook id: same value in both places.
openssl rand -hex 24
cp crowdsec/.env.example crowdsec/.env      # fill HA_CROWDSEC_WEBHOOK_URL
#    and `crowdsec_webhook_id` in home_automation/home_assistant/config/secrets.yaml

# 3. Log rotation on the host (Traefik does not rotate access logs).
sudo cp reverse-proxy/logrotate/traefik-access /etc/logrotate.d/
#    logrotate runs daily; to enforce the 20M size during an attack, run it hourly:
#    sudo systemctl edit logrotate.timer   ->   [Timer] OnCalendar= / OnCalendar=hourly

# 4. Start CrowdSec first, then recreate Traefik (static config changed).
(cd crowdsec && docker compose up -d)
(cd reverse-proxy && docker compose up -d --force-recreate)

# 5. Home Assistant: regenerate the package links and restart.
home_automation/scripts/HA_generate_real_config.sh
```

## Checks

```bash
docker exec crowdsec cscli bouncers list          # traefik bouncer, recent "last pull"
docker exec crowdsec cscli metrics                # acquisition: lines read/parsed > 0
docker exec crowdsec cscli metrics show appsec    # requests processed by the WAF
docker exec crowdsec cscli decisions list         # local bans
docker exec crowdsec cscli alerts list

# From outside (mobile data, not WireGuard). Hits the vpatch-env-access rule
# (blocked in-band). Repeating it a few times gets that IP banned for 4h:
curl -s -o /dev/null -w '%{http_code}\n' "https://<some-host>/.env"   # 403
# Unban yourself if needed:
docker exec crowdsec cscli decisions delete --ip <ip>
```

In Home Assistant: `sensor.crowdsec_bans_today` and `sensor.crowdsec_last_ban`
(Server view). Telegram only for exploit attempts (AppSec / virtual patching /
known-CVE probes).

## Notes

- If the bouncer key changes: `docker exec crowdsec cscli bouncers delete traefik`
  and restart the container so it registers the new one.
- False positives from the WAF: `cscli alerts list` shows the rule. Exclude it
  for a host/path with a custom AppSec rule rather than disabling AppSec.
- Updates: the image through Renovate's docker manager; the Traefik plugin
  through the custom manager on `reverse-proxy/traefik.yml`.
