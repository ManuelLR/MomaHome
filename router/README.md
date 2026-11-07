# Router (OpenWrt)

Belkin RT3200 / Linksys E8450 (UBI), OpenWrt 25.12, PPPoE WAN (`pppoe-wan`).
Its configuration is not deployed from this repo: this folder documents what is
set by hand so it can be redone after a reflash/upgrade (banIP recommends
starting from its default config after a system upgrade).

## banIP: inbound-only IP reputation blocking

Drops connections **started from the internet** (to the router and to the
port-forwards to the server) whose source is in a reputation list. Traffic
started from the LAN is never affected: banIP's inbound chains accept
`established,related` before checking any Set, and none of these feeds has an
outbound rule. No geoblocking.

| Setting | Why |
| --- | --- |
| Feeds `cinsscore debl dshield turris` | Attacker/scanner source lists, inbound only, ~33k IPs |
| No `doh` | Outbound block of public DoH servers: would break AdGuard if it uses DoH upstreams |
| No `firehol1` | Contains private ranges |
| `ban_feedin=blocklist` | The local blocklist (failed SSH/LuCI logins on the router) defaults to both directions |
| `ban_allowflag='udp 51820'` | WireGuard always reachable even from a listed IP (it answers nothing without a valid key anyway) |
| Reload every 6 h | Only `reload` re-downloads feeds (`start`/`restart` restore the backup). banIP's own example is daily |

```sh
apk update && apk add luci-app-banip curl   # curl: ETag support, only changed feeds are downloaded

uci set banip.global.ban_enabled='1'
uci set banip.global.ban_autodetect='1'
uci -q delete banip.global.ban_trigger
uci add_list banip.global.ban_trigger='wan'
uci add_list banip.global.ban_trigger='wan6'
uci -q delete banip.global.ban_feed
for f in cinsscore debl dshield turris; do uci add_list banip.global.ban_feed="$f"; done
uci -q delete banip.global.ban_feedin
uci add_list banip.global.ban_feedin='blocklist'
uci set banip.global.ban_allowflag='udp 51820'
uci commit banip
/etc/init.d/banip enable
/etc/init.d/banip restart

grep -q 'banip reload' /etc/crontabs/root 2>/dev/null || \
  echo '17 */6 * * * /etc/init.d/banip reload' >> /etc/crontabs/root
/etc/init.d/cron enable && /etc/init.d/cron restart
```

Checks:

```sh
/etc/init.d/banip status          # active, the 4 feeds in active_feeds
/etc/init.d/banip report          # Outbound column: "-" for every blocklist
nft list chain inet banIP wan-input | grep 51820
/etc/init.d/banip search <ip>
logread -e banIP | tail -20
```

## Statistics in Home Assistant

banIP counters reach Home Assistant through Netdata, like the rest of the
router metrics: charts `banip.feeds` (blocked packets per feed),
`banip.protection` (flood/invalid-packet drops) and `banip.elements` (IPs in
the lists), all in packets/min except the last one. Sensors in
`home_automation/home_assistant/config/packages/netdata/router/rest.yaml`
(section banIP), shown in the Net view.
