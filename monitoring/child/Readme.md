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

- **fping**: monitors latency/loss to 8.8.8.8 and 1.1.1.1
  Config: `/etc/netdata/fping.conf`

## Alarms

All alarms for child metrics are defined on the parent.
See `../parent/netdataconfig/health.d/router/`.

## Persisting the node identity across reboots

On OpenWrt, `/var/lib/netdata/` lives in tmpfs (RAM) and is wiped on every
reboot. This causes Netdata to generate a new machine GUID each time, making
the router appear as a different node after every restart.

The fix is the included `netdata-persist-guid` init script, which saves the
GUID to `/etc/netdata/machine_guid` (persistent flash storage) and restores
it before Netdata starts.

### One-time setup

```sh
# 1. Let Netdata run at least once, then save its generated GUID:
cp /var/lib/netdata/registry/netdata.public.unique.id \
   /etc/netdata/machine_guid

# 2. Install the init script:
cp netdata-persist-guid /etc/init.d/netdata-persist-guid
chmod +x /etc/init.d/netdata-persist-guid

# 3. Enable it so it runs on every boot (before Netdata):
/etc/init.d/netdata-persist-guid enable

# 4. Verify the start order is correct (should be 19, before netdata at 20):
ls -la /etc/rc.d/S19netdata-persist-guid
```

After the next reboot, the router will keep the same identity in the parent.
