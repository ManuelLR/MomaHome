# Netdata Child (OpenWrt Router)

Native Netdata agent on OpenWrt, configured to stream all metrics to the parent (Woody).

## Key configuration on the router

`/etc/netdata/stream.conf`:
```
[stream]
    enabled = yes
    destination = <Woody-IP>:19999
    api key = <shared-UUID>
```

## Plugins running on the child

- **fping**: monitors latency/loss to 8.8.8.8
  Config: `/etc/netdata/fping.conf`

## Alarms

All alarms for child metrics are defined on the parent.
See `../parent/netdataconfig/health.d/fping_router.conf`.
