# galley → Home Assistant

Feeds data from the **galley** freezer/diet app (PocketBase, self-hosted on
woody, LAN-only behind Traefik) into Home Assistant so the **Gicisky e-ink
panel** can display it. Read-only, polling every 5 min (no push hook — up to
5 min latency is acceptable by design).

- App / backend: <https://github.com/ManuelLR/galley>
- Data model: `pot` (recipe), `container` (taper: status freezer/fridge/consumed,
  `servings`, `freeze_date`, → `pot`), `meal` (week grid: `date`, `slot`,
  `text` or → `pot`), `meal_idea`.

## What this package creates

| File | Domain | Purpose |
|------|--------|---------|
| `rest.yaml` | `rest` | 3 pollers → raw `items` in attributes: `sensor.galley_freezer_raw`, `sensor.galley_fridge_raw`, `sensor.galley_meals_raw` |
| `input_datetime.yaml` | `input_datetime` | 4 UI-editable meal cut-off times (`galley_cutoff_breakfast/lunch/snack/dinner`) |
| `template.yaml` | `template` | Panel-ready `sensor.galley_panel_meals` + `sensor.galley_panel_inventory` |

The generated symlinks under `__auto_generated-config/{rest,input_datetime,template}/galley.yaml`
are what `configuration.yaml` actually includes (created by
`scripts/HA_generate_real_config.sh`, or by hand — see bottom).

## Panel data contract (what the Gicisky render binds to)

```jinja
{% set m = state_attr('sensor.galley_panel_meals', 'data') %}
{# m.today_label -> "jue 3 jul";  m.tomorrow_label #}
{# m.today / m.tomorrow -> [ {slot, label, text, red} ] #}
{#   comida/cena always present (text '—' if empty); others only if data;    #}
{#   TODAY drops a slot once its cut-off passed; tomorrow never hidden;       #}
{#   red=true on cook/buy -> use the RED channel                             #}

{% set i = state_attr('sensor.galley_panel_inventory', 'data') %}
{# i.fridge / i.freezer -> [ {name, code, count, servings, days, age, fossil} ] #}
{#   grouped by recipe, oldest first;  fossil=true (>6 months) -> RED         #}
{# i.freezer_containers / i.freezer_servings / i.fridge_* -> totals           #}
```

Render layout rules (applied at render time, since row capacity is pixel-bound):
- **Left = plan:** `today` then `tomorrow`. Truncate `tomorrow` with `…` if it
  doesn't fit.
- **Right = inventory:** show **all of `fridge`** (always), then `freezer`
  oldest-first; truncate the freezer **tail** with `… (+N)` — the urgent/fossil
  items are at the top and survive the cut.

### Quick check card (before wiring Gicisky)

Add a Markdown card to verify data is flowing:

```yaml
type: markdown
content: |
  **{{ state_attr('sensor.galley_panel_meals','data').today_label }}**
  {% for s in state_attr('sensor.galley_panel_meals','data').today %}
  - {{ s.label }}: {{ s.text }}{{ ' 🔴' if s.red }}
  {% endfor %}
  ---
  **Congelador** · {{ state_attr('sensor.galley_panel_inventory','data').freezer_servings }} raciones
  {% for g in state_attr('sensor.galley_panel_inventory','data').freezer %}
  - {{ '⚠ ' if g.fossil }}{{ g.name }} ({{ g.code }}) · {{ g.age }} · {{ g.count }}📦
  {% endfor %}
```

## One-time setup

### 1. Create a read-only service user in galley
In the PocketBase admin UI (`https://<galley-domain>/_/`) → collection `users`
→ **New record**: e.g. `homeassistant@moma.place` + a password. (Any authed user
can read; API rules only require `@request.auth.id != ""`.)

### 2. Mint a long-lived token (recommended: superuser *impersonate*)
Default auth tokens expire in **14 days**. To avoid re-issuing, mint a
long-duration token with the superuser *impersonate* endpoint (PocketBase
v0.23+). Run once, from a machine on the LAN:

```bash
GALLEY=https://<galley-domain>

# a) superuser token
SU=$(curl -s "$GALLEY/api/collections/_superusers/auth-with-password" \
  -H 'Content-Type: application/json' \
  -d '{"identity":"<admin-email>","password":"<admin-pass>"}' | jq -r .token)

# b) find the service user id
UID=$(curl -s "$GALLEY/api/collections/users/records?filter=(email='homeassistant@moma.place')" \
  -H "Authorization: $SU" | jq -r '.items[0].id')

# c) impersonate it with a 10-year token (315360000 s)
curl -s "$GALLEY/api/collections/users/impersonate/$UID" \
  -H "Authorization: $SU" -H 'Content-Type: application/json' \
  -d '{"duration":315360000}' | jq -r .token
```

Copy the printed token into `secrets.yaml` (below). Store it **raw** (no
`Bearer ` prefix — PocketBase reads the raw `Authorization` header).

> Fallback without impersonate: just `auth-with-password` as the service user
> to get a 14-day token — but you'd have to refresh it periodically.

### 3. Fill secrets
Add to `config/secrets.yaml` (placeholders are in `secrets.example.yaml`):

```yaml
galley_container_resource: "https://<galley-domain>/api/collections/container/records"
galley_meal_resource:      "https://<galley-domain>/api/collections/meal/records"
galley_api_token:          "<token-from-step-2>"
```

### 4. Generate symlinks + restart
```bash
cd home_automation && ./scripts/HA_generate_real_config.sh   # or create by hand
```
Then check config and restart HA. Verify `sensor.galley_*_raw` populate, then
`sensor.galley_panel_*` in Developer Tools → States.

## Notes
- **Network:** HA runs `network_mode: host` on woody (LAN IP in
  `192.168.200.0/24`), so it reaches galley through the LAN-only Traefik route.
- **UTC:** PocketBase date macros are UTC; `meals` are fetched from `@yesterday`
  and the template selects today/tomorrow by **local** date, so the skew is
  harmless.
- **Refresh:** `template.yaml` recomputes every 5 min (time_pattern) so the
  meal-slot time-hiding kicks in without waiting for a data change.
