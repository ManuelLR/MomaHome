# Router (OpenWrt)

Belkin RT3200 / Linksys E8450 (UBI), OpenWrt 25.12, PPPoE WAN. Configured by
hand; this documents it so it can be redone after an upgrade.

## banIP: inbound-only IP reputation blocking

Drops connections started from the internet whose source is in a reputation
list. Connections started from the LAN are never affected. No geoblocking.

| Setting | Why |
| --- | --- |
| Feeds `cinsscore debl dshield turris` | Inbound-only attacker/scanner lists |
| No `doh` | Blocks outbound DoH, could break AdGuard's upstreams |
| No `firehol1` | Contains private ranges |
| `ban_feedin=blocklist` | Local blocklist (failed router logins) is bidirectional by default |
| `ban_allowflag='udp 51820'` | WireGuard reachable even from a listed IP |
| Reload every 6 h | Only `reload` re-downloads the feeds |

```sh
apk update && apk add luci-app-banip curl

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

Through Netdata (charts `banip.feeds`, `banip.protection`, `banip.elements`),
see the banIP section of `packages/netdata/router/rest.yaml`.
